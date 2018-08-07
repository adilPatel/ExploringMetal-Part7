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

let buffersInFlight = 3

enum RendererError: Error {
    case badVertexDescriptor
}

struct ShaderConstants {
    var modelViewMatrix = matrix_identity_float4x4
    var projectionMatrix = matrix_identity_float4x4
    var normalMatrix = matrix_identity_float3x3
}

class Renderer: NSObject, MTKViewDelegate {

    // A handle to our device (which is the GPU)
    public let device: MTLDevice
    
    public let cameraController: CameraController
    
    // The camera of the scene
    var camera: Camera
    
    // The Metal render pipeline state
    var pipelineState: MTLRenderPipelineState
    
    // The Metal depth stencil state
    var depthState: MTLDepthStencilState
    
    // The Metal command queue
    let commandQueue: MTLCommandQueue
    
    // Moves our shape to camera space
    var modelMatrix = float4x4()
    
    // The array of buffers used
    var constantBuffers: [ShaderConstants]
    
    // The index of the current buffer being written to and binded
    var constantBufferIndex = 0
    
    // Will send our vertex array to Metal
    var vertexBuffer: MTLBuffer!
    
    // Will use to describe the polygons
    var indexBuffer: MTLBuffer!
    
    // Contains data of the geometry
    var subMesh: MTKSubmesh!
    
    // Self-explanatory
    var sphereTexture: MTLTexture!
    
    // The texture sampler which will be passed on to Metal
    var samplerState: MTLSamplerState?
    
    var semaphore = DispatchSemaphore(value: buffersInFlight)
    
    init?(metalKitView: MTKView) {
        // Initialising the crucial view, device, and command queue parameters
        device = metalKitView.device!
        
        guard let queue = device.makeCommandQueue() else {
            return nil
        }
        commandQueue = queue
        
        metalKitView.depthStencilPixelFormat = .depth32Float_stencil8
        
        // Initialising the transform matrices
        let size = metalKitView.bounds.size
        let aspectRatio = Float(size.width) / Float(size.height)
        camera = Camera(fovy: Maths.degreesToRadians(degrees: 65.0),
                        aspectRatio: aspectRatio,
                        nearZ: 0.1,
                        farZ: 100.0)
        cameraController = CameraController(camera: camera)
        
        modelMatrix = Maths.createTranslationMatrix(vector: float3(0.0, 0.0, -5.0))
        
        var shaderConstant = ShaderConstants()
        shaderConstant.modelViewMatrix  = modelMatrix
        shaderConstant.projectionMatrix = camera.projectionMatrix
        shaderConstant.normalMatrix = Maths.createNormalMatrix(matrix: modelMatrix)
        constantBuffers = Array<ShaderConstants>(repeating: shaderConstant, count: buffersInFlight)
        
        let vertexDescriptor = makeVertexDescriptor()
        
        // Create the box in a more elegant and procedural manner
        let mesh: MTKMesh
        let componentsPerRow = 3 + 3 + 2
        let stride = MemoryLayout<Float>.size * componentsPerRow
        let endPoint = 2601
        
        do {
            mesh = try makeMesh(device: device, vertexDescriptor: vertexDescriptor)
            let mdlVertexBuffer = mesh.vertexBuffers[0].buffer
            vertexBuffer = device.makeBuffer(bytes: mdlVertexBuffer.contents(),
                                                  length: stride * endPoint,
                                                  options: .cpuCacheModeWriteCombined)
            vertexBuffer.label = "Sphere Vertex Buffer"
            subMesh = mesh.submeshes[0]
            indexBuffer = subMesh.indexBuffer.buffer
            indexBuffer.label = "Sphere Index Buffer"
        } catch {
            print("ERROR: Unable to create mesh.  Error info: \(error)")
            return nil
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
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.label = "Main Render Pipeline State"
        
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            print("ERROR: Failed to create the render pipeline state with error:\n\(error)")
            return nil
        }
        
        // Depth testing
        let depthStateDesciptor = MTLDepthStencilDescriptor()
        depthStateDesciptor.depthCompareFunction = .less
        depthStateDesciptor.isDepthWriteEnabled = true
        depthStateDesciptor.label = "Main Depth State"
        guard let state = device.makeDepthStencilState(descriptor:depthStateDesciptor) else { return nil }
        depthState = state
        
        do {
            sphereTexture = try createTexture(device: device, assetName: "Atlas", assetExtension: "jpeg")
            sphereTexture.label = "Atlas Texture"
            
        } catch {
            print("ERROR: Failed to load texture with error:\n\(error)")
        }
        
       samplerState = createSampler(device: device)
        
       super.init()

        
    }

    func updateGameState() {
        
        camera.updateState()
        let modelViewMatrix = camera.currentViewMatrix * modelMatrix
        let normalMatrix = Maths.createNormalMatrix(matrix: modelViewMatrix)
        constantBuffers[constantBufferIndex].modelViewMatrix = modelViewMatrix
        constantBuffers[constantBufferIndex].normalMatrix = normalMatrix
        
    }


    func draw(in view: MTKView) {
        /// Per frame updates hare
        
        // Halt the execution of this function until the semaphore is signalled
        let _ = semaphore.wait(timeout: .distantFuture)
        
        // So now we need a command buffer...
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            
            commandBuffer.label = "Application Command Buffer"
            updateGameState()
            
            if let renderPassDescriptor = view.currentRenderPassDescriptor,
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
     
                renderEncoder.label = "Application Render Encoder"
                
                // Copy the data into a buffer and set the render pipeline state
                renderEncoder.pushDebugGroup("Encoding vertex arguments")
                var constantBuffer = constantBuffers[constantBufferIndex]
                renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                renderEncoder.setVertexBytes(&constantBuffer, length: MemoryLayout<ShaderConstants>.size, index: 1)
                renderEncoder.popDebugGroup()
                
                renderEncoder.pushDebugGroup("Assigning render and depth states")
                renderEncoder.setRenderPipelineState(pipelineState)
                renderEncoder.setDepthStencilState(depthState)
                renderEncoder.popDebugGroup()
                
                renderEncoder.pushDebugGroup("Assigning fragment arguments")
                renderEncoder.setFragmentTexture(sphereTexture, index: 0)
                renderEncoder.setFragmentSamplerState(samplerState, index: 0)
                renderEncoder.popDebugGroup()
                
                renderEncoder.pushDebugGroup("Setting the cull mode")
                renderEncoder.setFrontFacing(.counterClockwise)
                renderEncoder.setCullMode(.back)
                renderEncoder.popDebugGroup()
                
                let primitiveType = subMesh.primitiveType
                let indexCount = subMesh.indexCount
                let indexType  = subMesh.indexType
                
                renderEncoder.pushDebugGroup("Draw call")
                renderEncoder.drawIndexedPrimitives(type: primitiveType,
                                                    indexCount: indexCount,
                                                    indexType: indexType,
                                                    indexBuffer: indexBuffer,
                                                    indexBufferOffset: 0)
                renderEncoder.popDebugGroup()
                
                renderEncoder.endEncoding()
                
                // We'll render to the screen. MetalKit gives us drawables which we use for that
                if let drawable = view.currentDrawable {
                    commandBuffer.present(drawable)
                }
                
            }
            
            commandBuffer.addCompletedHandler {_ in
                self.semaphore.signal()
            }
            commandBuffer.commit()
            constantBufferIndex = (constantBufferIndex + 1) % buffersInFlight
            
        }
        
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        /// Respond to drawable size or orientation changes here

        let aspect = Float(size.width) / Float(size.height)
        camera.projectionMatrix = Maths.createProjectionMatrix(fovy: Maths.degreesToRadians(degrees: 65.0),
                                                               aspectRatio: aspect,
                                                               nearZ: 0.1,
                                                               farZ: 100.0)
        for (i, _) in constantBuffers.enumerated() {
            constantBuffers[i].projectionMatrix = camera.projectionMatrix
        }
        
    }
    
    
}

func createSampler(device: MTLDevice) -> MTLSamplerState? {
    
    // Configure the sampler
    let samplerDescriptor = MTLSamplerDescriptor()
    samplerDescriptor.sAddressMode = .repeat
    samplerDescriptor.tAddressMode = .repeat
    samplerDescriptor.minFilter = .linear
    samplerDescriptor.magFilter = .linear
    samplerDescriptor.mipFilter = .linear
    samplerDescriptor.label = "Atlas Texture Sampler"
    
    // We could've used a bilinear filter for minification, but it fails when the pixel
    // covers more than 4 texels. This is because bilinear filters blend four texels
    
    return device.makeSamplerState(descriptor: samplerDescriptor)
    
}

func createTexture(device: MTLDevice, assetName: String, assetExtension: String) throws -> MTLTexture? {
    
    // Here we use MTKTextureLoader to handle our texture loading
    let textureLoader = MTKTextureLoader(device: device)
    let tempPath = Bundle.main.path(forResource: assetName, ofType: assetExtension)
    
    let storageMode = NSNumber(value: MTLStorageMode.`private`.rawValue)
    let textureUsage = NSNumber(value: MTLTextureUsage.shaderRead.rawValue)
    let mipMapCreation = NSNumber(value: true)
    let textureOptions = [MTKTextureLoader.Option.textureStorageMode : storageMode,
                          MTKTextureLoader.Option.textureUsage : textureUsage,
                          MTKTextureLoader.Option.generateMipmaps : mipMapCreation]
    if let path = tempPath {
        let url = URL(fileURLWithPath: path)
        return try textureLoader.newTexture(URL: url, options: textureOptions)
        
    } else {
        return nil
    }
    
}

func makeVertexDescriptor() -> MTLVertexDescriptor {
    // Create the vertex descriptor first...
    let vertexDescriptor = MTLVertexDescriptor()
    
    // Position
    vertexDescriptor.attributes[0].format = .float3
    vertexDescriptor.attributes[0].offset = 0 // Three floats causes 12 bytes of offset!
    vertexDescriptor.attributes[0].bufferIndex = 0
    
    // Normal
    vertexDescriptor.attributes[1].format = .float3
    vertexDescriptor.attributes[1].offset = 12 // This value is cumulative!
    vertexDescriptor.attributes[1].bufferIndex = 0
    
    // Texcoord
    vertexDescriptor.attributes[2].format = .float2
    vertexDescriptor.attributes[2].offset = 24
    vertexDescriptor.attributes[2].bufferIndex = 0
    
    // Interleave them
    vertexDescriptor.layouts[0].stride = 32
    vertexDescriptor.layouts[0].stepRate = 1
    vertexDescriptor.layouts[0].stepFunction = .perVertex
    
    return vertexDescriptor
}

func makeMesh(device: MTLDevice, vertexDescriptor: MTLVertexDescriptor) throws -> MTKMesh {
    
    // The "glue" between Model I/O and Metal
    let allocator = MTKMeshBufferAllocator(device: device)
    
    // Create the sphere mesh
    let mdlMesh = MDLMesh(sphereWithExtent: float3(2.0, 2.0, 2.0),
                          segments: uint2(50, 50),
                          inwardNormals: false,
                          geometryType: .triangles,
                          allocator: allocator)
    
    
    // Lay out the vertex/normal/texcoord information in the format we defined with the
    // vertex descriptor
    let mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(vertexDescriptor)
    
    guard let attributes = mdlVertexDescriptor.attributes as? [MDLVertexAttribute] else {
        throw RendererError.badVertexDescriptor
    }
    attributes[0].name = MDLVertexAttributePosition
    attributes[1].name = MDLVertexAttributeNormal
    attributes[2].name = MDLVertexAttributeTextureCoordinate
    
    mdlMesh.vertexDescriptor = mdlVertexDescriptor
    
    return try MTKMesh(mesh: mdlMesh, device: device)
    
}


