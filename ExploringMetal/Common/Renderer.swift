//
//  Renderer.swift
//  ExploringMetal
//
//  Created by Adil Patel on 31/05/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

// Our platform independent renderer class

import Metal
import MetalKit
import simd

enum RendererError: Error {
    case badVertexDescriptor
}

let buffersInFlight = 3

class Renderer: NSObject, MTKViewDelegate {

    // A handle to our device (which is the GPU)
    public let device: MTLDevice
    
    // Controls our camera
    public let cameraController: CameraController
    
    // The camera of the scene
    var camera: Camera
    
    // The Metal render pipeline state
    var meshPipelineState: MTLRenderPipelineState!
    
    // The Metal depth stencil state
    var depthState: MTLDepthStencilState
    
    // The Metal command queue
    let commandQueue: MTLCommandQueue
    
    // The array of buffers used
    var constantBuffers = Array<MTLBuffer>()
    
    // The index of the current buffer being written to and binded
    var constantBufferIndex = 0
    
    // The data which is constant across all objects in a single frame
    var frameConstants: PerFrameConstants
        
    // The texture sampler which will be passed on to Metal
    var sampler: Sampler
    
    // All the meshes present in this scene
    var meshes = Array<Mesh>()
    
    // All the per-object transforms expressed as data structs
    var objectTransforms = Array<ObjectTransforms>()
    
    // This is similar to the above, but only for the skybox
    var skyboxTransforms: [SkyboxTransforms]
    
    // A handle to our skybox
    var skybox: Skybox!
    
    // All the model matrices for each object
    var modelMatrices = Array<float4x4>()
    
    // The textures for each object
    var textures = Array<Texture>()
    
    // Our semaphore for triple buffering
    var semaphore = DispatchSemaphore(value: buffersInFlight)
    
    init?(metalKitView: MTKView) {
        // Initialising the crucial view, device, and command queue parameters
        device = metalKitView.device!
        
        guard let queue = device.makeCommandQueue() else {
            return nil
        }
        commandQueue = queue
        
        metalKitView.depthStencilPixelFormat = .depth32Float_stencil8
        
        // Depth testing
        let depthStateDesciptor = MTLDepthStencilDescriptor()
        depthStateDesciptor.depthCompareFunction = .less
        depthStateDesciptor.isDepthWriteEnabled = true
        depthStateDesciptor.label = "Main Depth State"
        guard let state = device.makeDepthStencilState(descriptor:depthStateDesciptor) else { return nil }
        depthState = state
        
        sampler = Sampler(descriptor: createSamplerDescriptor(), device: device)
        
        // Initialising the camera
        let size = metalKitView.bounds.size
        let aspectRatio = Float(size.width) / Float(size.height)
        camera = Camera(fovy: Maths.degreesToRadians(degrees: 65.0),
                        aspectRatio: aspectRatio,
                        nearZ: 0.1,
                        farZ: 100.0,
                        position: float3(-5.0, 1.0, 5.0))
        cameraController = CameraController(camera: camera)
        let projectionMatrix = camera.projectionMatrix
        
        // Then the frame constants (which are consistent across all objects)
        frameConstants = PerFrameConstants()
        frameConstants.projectionMatrix = projectionMatrix
        
        // Allocate the skybox constant buffers. We'll also use 3 in case of triple-buffering
        var skyConstants = SkyboxTransforms()
        skyConstants.modelViewProjectionMatrix = projectionMatrix * camera.rotationMatrix
        skyboxTransforms = Array<SkyboxTransforms>(repeating: skyConstants, count: buffersInFlight)
        
        super.init()
        
        initialiseScene()
        
        // At this point, we only have an array full of model view matrices. We have to create the object
        // transform structures
        for modelMatrix in modelMatrices {
            var transform = ObjectTransforms()
            transform.modelViewMatrix = camera.currentViewMatrix * modelMatrix
            transform.normalMatrix = Maths.createNormalMatrix(fromMVMatrix: transform.modelViewMatrix)
            objectTransforms.append(transform)
        }
        
        // Now we allocate the three MTLBuffers in flight and fill them up
        var bufferLength = MemoryLayout<PerFrameConstants>.stride
        bufferLength += MemoryLayout<ObjectTransforms>.stride * objectTransforms.count
        for _ in 0..<buffersInFlight {
            
            if let buffer = device.makeBuffer(length: bufferLength, options: .cpuCacheModeWriteCombined) {
                updateAllConstants(buffer)
                constantBuffers.append(buffer)
            }
            
        }
        
        // We're creating handles to the shaders...
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "helloVertexShader")
        let fragmentFunction = library?.makeFunction(name: "helloFragmentShader")
 
        // Here we create the render pipeline state. However, Metal doesn't allow
        // us to create one directly; we must use a descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.vertexDescriptor = meshes[0].vertexDescriptor
        pipelineDescriptor.label = "Main Render Pipeline State"
        
        do {
            try meshPipelineState = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            print("ERROR: Failed to create the render pipeline state with error:\n\(error)")
            return nil
        }
        
        let skyboxVertexFunction = library?.makeFunction(name: "SkyboxVertexShader")
        let skyboxFragmentFunction = library?.makeFunction(name: "SkyboxFragmentShader")
        // And now the skybox
        skybox = Skybox(device: device,
                        vertexFunction: skyboxVertexFunction,
                        fragmentFunction: skyboxFragmentFunction,
                        colourPixelFormat: metalKitView.colorPixelFormat,
                        depthStencilPixelFormat: metalKitView.depthStencilPixelFormat)
        
    }
    
    func initialiseScene() {
        
        let biplaneGeometry = MeshGeometry(modelFile: "Plane.obj", device: device)
        let biplaneMesh = Mesh(name: "Biplane", meshGeometry: biplaneGeometry)
        meshes.append(biplaneMesh)
        
        let biplaneTexture = Texture(name: "Biplane Texture",
                                     file: "tex_airplane02.jpg",
                                     createMipMaps: true,
                                     textureStorage: .private,
                                     usage: .shaderRead,
                                     cpuCacheMode: .defaultCache,
                                     device: device)
        textures.append(biplaneTexture)
        modelMatrices.append(matrix_identity_float4x4)
        
        
    }

    func updateGameState() {
        
        camera.updateState()
        let projectionMatrix = camera.projectionMatrix
        let viewMatrix = camera.currentViewMatrix
        
        // First we update all the per-object constants in the array
        for (i, modelMatrix) in modelMatrices.enumerated() {
            
            let modelViewMatrix = viewMatrix * modelMatrix
            let normalMatrix = Maths.createNormalMatrix(fromMVMatrix: modelViewMatrix)
            var transforms = ObjectTransforms()
            transforms.modelViewMatrix = modelViewMatrix
            transforms.normalMatrix = normalMatrix
            
            objectTransforms[i] = transforms
            
        }
        
        // After which, we store them in the active constant buffer
        updateAllConstants(constantBuffers[constantBufferIndex])
        
        // Then the skybox. It keeps the scene alive... it's the real MVP :')
        let skyMVP = projectionMatrix * camera.rotationMatrix
        skyboxTransforms[constantBufferIndex].modelViewProjectionMatrix = skyMVP
        
    }


    func draw(in view: MTKView) {
        /// Per frame updates hare
        
        // Halt the execution of this function until the semaphore is signalled
        let _ = semaphore.wait(timeout: .distantFuture)
        
        // So now we need a command buffer...
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            
            commandBuffer.label = "Application Command Buffer"
            updateGameState()
            
            let renderPassDescriptor = view.currentRenderPassDescriptor
            renderPassDescriptor?.colorAttachments[0].loadAction = .dontCare // Don't need to clear to black 
            if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor!) {
            
//                renderEncoder.label = "Application Render Encoder"
                
                renderEncoder.pushDebugGroup("Assigning render and depth states")
                renderEncoder.setRenderPipelineState(meshPipelineState)
                renderEncoder.setDepthStencilState(depthState)
                renderEncoder.popDebugGroup()

                renderEncoder.pushDebugGroup("Setting the cull mode")
                renderEncoder.setFrontFacing(.counterClockwise)
                renderEncoder.setCullMode(.back)
                renderEncoder.popDebugGroup()

                let constantBuffer = constantBuffers[constantBufferIndex]

                renderEncoder.pushDebugGroup("Working on the meshes")
                renderEncoder.setVertexBuffer(constantBuffer, offset: 0, index: BufferIndex.localUniforms.rawValue)
                renderEncoder.setVertexBuffer(constantBuffer, offset: 0, index: BufferIndex.perFrameConstants.rawValue)

                // Below looks kinda complex, but it really isn't. All we do is iterate though all meshes,
                // bind their constants to the shaders, and then draw them. We increment the buffer offset in each
                // step to select the correct region of the constant buffer
                var offset = MemoryLayout<PerFrameConstants>.stride
                let stride = MemoryLayout<ObjectTransforms>.stride
                for (i, mesh) in meshes.enumerated() {
                    renderEncoder.pushDebugGroup("Working on \(mesh.mtkMesh.name)")

                    renderEncoder.pushDebugGroup("Encoding vertex arguments")
                    mesh.bindToVertexShader(encoder: renderEncoder)
                    renderEncoder.setVertexBufferOffset(offset, index: BufferIndex.localUniforms.rawValue)
                    renderEncoder.popDebugGroup()

                    offset += stride

                    renderEncoder.pushDebugGroup("Encoding fragment arguments")
                    textures[i].bindToFragmentShader(encoder: renderEncoder, index: 0)
                    sampler.bindToFragmentShader(encoder: renderEncoder, index: 0)
                    renderEncoder.popDebugGroup()

                    renderEncoder.pushDebugGroup("Drawing")
                    mesh.drawMesh(encoder: renderEncoder)
                    renderEncoder.popDebugGroup()

                    renderEncoder.popDebugGroup()
                }
                renderEncoder.popDebugGroup()

                renderEncoder.pushDebugGroup("Tackling the Skybox")
                let skyboxConstantBuffer = skyboxTransforms[constantBufferIndex]
                skybox.draw(encoder: renderEncoder, constants: skyboxConstantBuffer)
                renderEncoder.popDebugGroup()
                
                renderEncoder.endEncoding()
                
                // We'll render to the screen. MetalKit gives us drawables which we use for that
                if let drawable = view.currentDrawable {
                    commandBuffer.present(drawable)
                }
                
                renderEncoder.label = "Application Render Encoder"
            }
            
            commandBuffer.addCompletedHandler {_ in
                self.semaphore.signal()
            }
            commandBuffer.commit()
            constantBufferIndex = (constantBufferIndex + 1) % buffersInFlight
            
        }
        
    }
    
    func updateAllConstants(_ buffer: MTLBuffer) {
        
        // This is the pointer to the beginning of the buffer contents
        var ptr = buffer.contents()
        
        // Populate the frame constants
        ptr.copyMemory(from: &frameConstants, byteCount: MemoryLayout<PerFrameConstants>.stride)
        ptr += MemoryLayout<PerFrameConstants>.stride
        
        // Then the per-object constants. We constantly offset the pointer to change the region
        // of the buffer, after which we copy the data for each object
        let stride = MemoryLayout<ObjectTransforms>.stride
        for (i, _) in objectTransforms.enumerated() {
            ptr.copyMemory(from: &objectTransforms[i], byteCount: stride)
            ptr += stride
        }
        
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        /// Respond to drawable size or orientation changes here

        let aspect = Float(size.width) / Float(size.height)
        camera.projectionMatrix = Maths.createProjectionMatrix(fovy: Maths.degreesToRadians(degrees: 65.0),
                                                               aspectRatio: aspect,
                                                               nearZ: 0.1,
                                                               farZ: 100.0)
        frameConstants.projectionMatrix = camera.projectionMatrix
        
    }
    
    
}


