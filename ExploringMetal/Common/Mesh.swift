//
//  Mesh.swift
//  ExploringMetal
//
//  Created by Adil Patel on 16/08/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import Foundation
import Metal
import MetalKit
import simd

enum MeshError: Error {
    case badVertexDescriptor
}

enum VertexLayout {
    case positionNormalTexcoord
    case positionNormal
    case positionTexcoord
}

struct MeshGeometry {
    
    var mtkMesh: MTKMesh!
    let vertexDescriptor: MTLVertexDescriptor!
    
    init(modelFile: String, device: MTLDevice) {
        
        // For now, we'll create all models the same
        vertexDescriptor = MeshGeometry.createVNTDescriptor()
        
        // Create the URL for the model file
        let separated = modelFile.components(separatedBy: ".")
        guard let url = Bundle.main.url(forResource: separated[0], withExtension: separated[1]) else {
            print("ERROR: Failed to load \(modelFile)!")
            return
        }
        
        // This is the same procedure as the other shapes
        let allocator = MTKMeshBufferAllocator(device: device)
        let mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(vertexDescriptor)
        guard let attributes = mdlVertexDescriptor.attributes as? [MDLVertexAttribute] else {
            return
        }
        attributes[0].name = MDLVertexAttributePosition
        attributes[1].name = MDLVertexAttributeNormal
        attributes[2].name = MDLVertexAttributeTextureCoordinate

        // Model I/O fetches an asset, which is a superclass for meshes, lights, and other stuff
        let asset = MDLAsset(url: url, vertexDescriptor: mdlVertexDescriptor, bufferAllocator: allocator)
        guard let mdlMesh = asset[0] as? MDLMesh else {
            print("ERROR: Failed to create mesh named \(separated[0])!")
            return
        }
        
        // And we construct our MTKMesh
        do {
            try mtkMesh = MTKMesh(mesh: mdlMesh, device: device)
        } catch {
            print("ERROR: Failed to allocate MetalKit mesh for \(separated[0])!")
        }
        
    }
    
    init(sphereWithExtent extent: float3,
         segments: uint2,
         layout: VertexLayout,
         device: MTLDevice) {
        
        // The "glue" between Model I/O and Metal
        let allocator = MTKMeshBufferAllocator(device: device)
        
        // Create the sphere mesh
        let mdlMesh = MDLMesh(sphereWithExtent: extent,
                              segments: segments,
                              inwardNormals: false,
                              geometryType: .triangles,
                              allocator: allocator)
        
        // Lay out the information in a vertex descriptor
        switch layout {
        case .positionNormalTexcoord:
            self.vertexDescriptor = MeshGeometry.createVNTDescriptor()
        case .positionTexcoord:
            self.vertexDescriptor = MeshGeometry.createVTDescriptor()
        case .positionNormal:
            self.vertexDescriptor = MeshGeometry.createVNDescriptor()
        }
        let mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(self.vertexDescriptor)
        guard let attributes = mdlVertexDescriptor.attributes as? [MDLVertexAttribute] else {
            return
        }
        
        // Choose the correct attributes based on the layout
        switch layout {
        case .positionNormalTexcoord:
            attributes[0].name = MDLVertexAttributePosition
            attributes[1].name = MDLVertexAttributeNormal
            attributes[2].name = MDLVertexAttributeTextureCoordinate
        case .positionTexcoord:
            attributes[0].name = MDLVertexAttributePosition
            attributes[1].name = MDLVertexAttributeTextureCoordinate
        case .positionNormal:
            attributes[0].name = MDLVertexAttributePosition
            attributes[1].name = MDLVertexAttributeNormal
        }
        
        mdlMesh.vertexDescriptor = mdlVertexDescriptor
        
        do {
            try mtkMesh = MTKMesh(mesh: mdlMesh, device: device)
        } catch {
            print("ERROR: Failed to create sphere!")
        }
        
    }
    
    init(boxWithExtent extent: float3,
         segments: vector_uint3,
         layout: VertexLayout,
         device: MTLDevice) {
        
        // The "glue" between Model I/O and Metal
        let allocator = MTKMeshBufferAllocator(device: device)
        
        let mdlMesh = MDLMesh(boxWithExtent: extent,
                              segments: segments,
                              inwardNormals: false,
                              geometryType: .triangles,
                              allocator: allocator)
        
        // Lay out the information in a vertex descriptor
        switch layout {
        case .positionNormalTexcoord:
            self.vertexDescriptor = MeshGeometry.createVNTDescriptor()
        case .positionTexcoord:
            self.vertexDescriptor = MeshGeometry.createVTDescriptor()
        case .positionNormal:
            self.vertexDescriptor = MeshGeometry.createVNDescriptor()
        }
        let mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(self.vertexDescriptor)
        guard let attributes = mdlVertexDescriptor.attributes as? [MDLVertexAttribute] else {
            return
        }
        
        switch layout {
        case .positionNormalTexcoord:
            attributes[0].name = MDLVertexAttributePosition
            attributes[1].name = MDLVertexAttributeNormal
            attributes[2].name = MDLVertexAttributeTextureCoordinate
        case .positionTexcoord:
            attributes[0].name = MDLVertexAttributePosition
            attributes[1].name = MDLVertexAttributeTextureCoordinate
        case .positionNormal:
            attributes[0].name = MDLVertexAttributePosition
            attributes[1].name = MDLVertexAttributeNormal
        }
        
        mdlMesh.vertexDescriptor = mdlVertexDescriptor
        
        
        do {
            try mtkMesh = MTKMesh(mesh: mdlMesh, device: device)
        } catch {
            print("ERROR: Failed to create box!")
        }
        
    }
    
    init(planeWithExtent extent: float3,
         segments: uint2,
         layout: VertexLayout,
         device: MTLDevice) {
        
        // The "glue" between Model I/O and Metal
        let allocator = MTKMeshBufferAllocator(device: device)
        
        let mdlMesh = MDLMesh(planeWithExtent: extent,
                              segments: segments,
                              geometryType: .triangles,
                              allocator: allocator)
        
        // Lay out the information in a vertex descriptor
        switch layout {
        case .positionNormalTexcoord:
            self.vertexDescriptor = MeshGeometry.createVNTDescriptor()
        case .positionTexcoord:
            self.vertexDescriptor = MeshGeometry.createVTDescriptor()
        case .positionNormal:
            self.vertexDescriptor = MeshGeometry.createVNDescriptor()
        }
        let mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(self.vertexDescriptor)
        guard let attributes = mdlVertexDescriptor.attributes as? [MDLVertexAttribute] else {
            return
        }
        
        switch layout {
        case .positionNormalTexcoord:
            attributes[0].name = MDLVertexAttributePosition
            attributes[1].name = MDLVertexAttributeNormal
            attributes[2].name = MDLVertexAttributeTextureCoordinate
        case .positionTexcoord:
            attributes[0].name = MDLVertexAttributePosition
            attributes[1].name = MDLVertexAttributeTextureCoordinate
        case .positionNormal:
            attributes[0].name = MDLVertexAttributePosition
            attributes[1].name = MDLVertexAttributeNormal
        }
        
        mdlMesh.vertexDescriptor = mdlVertexDescriptor
                
        do {
            try mtkMesh = MTKMesh(mesh: mdlMesh, device: device)
        } catch {
            print("ERROR: Failed to create plane!")
        }
        
    }
    
    private static func createVNTDescriptor() -> MTLVertexDescriptor {
        
        let vertexDescriptor = MTLVertexDescriptor()
        
         // Position
        vertexDescriptor.attributes[VertexAttributeVNT.position.rawValue].format = .float3
        vertexDescriptor.attributes[VertexAttributeVNT.position.rawValue].offset = 0
        vertexDescriptor.attributes[VertexAttributeVNT.position.rawValue].bufferIndex = BufferIndex.meshPositions.rawValue
        
        // Normal
        vertexDescriptor.attributes[VertexAttributeVNT.normal.rawValue].format = .float3
        vertexDescriptor.attributes[VertexAttributeVNT.normal.rawValue].offset = 12
        vertexDescriptor.attributes[VertexAttributeVNT.normal.rawValue].bufferIndex = BufferIndex.meshPositions.rawValue
        
        // Texcoord
        vertexDescriptor.attributes[VertexAttributeVNT.texcoord.rawValue].format = .float2
        vertexDescriptor.attributes[VertexAttributeVNT.texcoord.rawValue].offset = 24
        vertexDescriptor.attributes[VertexAttributeVNT.texcoord.rawValue].bufferIndex = BufferIndex.meshPositions.rawValue
        
        // Interleave them
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        vertexDescriptor.layouts[0].stride = 32
        
        return vertexDescriptor
    }
    
    private static func createVTDescriptor() -> MTLVertexDescriptor {
        
        let vertexDescriptor = MTLVertexDescriptor()
        
        // Position
        vertexDescriptor.attributes[VertexAttributeVT.position.rawValue].format = .float3
        vertexDescriptor.attributes[VertexAttributeVT.position.rawValue].offset = 0
        vertexDescriptor.attributes[VertexAttributeVT.position.rawValue].bufferIndex = BufferIndex.meshPositions.rawValue
        
        // Texcoord
        vertexDescriptor.attributes[VertexAttributeVT.texcoord.rawValue].format = .float2
        vertexDescriptor.attributes[VertexAttributeVT.texcoord.rawValue].offset = 12
        vertexDescriptor.attributes[VertexAttributeVT.texcoord.rawValue].bufferIndex = BufferIndex.meshPositions.rawValue
        
        // Interleave them
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        vertexDescriptor.layouts[0].stride = 20
        
        return vertexDescriptor
        
    }
    
    private static func createVNDescriptor() -> MTLVertexDescriptor {
        
        let vertexDescriptor = MTLVertexDescriptor()
        
        // Position
        vertexDescriptor.attributes[VertexAttributeVN.position.rawValue].format = .float3
        vertexDescriptor.attributes[VertexAttributeVN.position.rawValue].offset = 0
        vertexDescriptor.attributes[VertexAttributeVN.position.rawValue].bufferIndex = BufferIndex.meshPositions.rawValue
        
        // Texcoord
        vertexDescriptor.attributes[VertexAttributeVN.normal.rawValue].format = .float2
        vertexDescriptor.attributes[VertexAttributeVN.normal.rawValue].offset = 12
        vertexDescriptor.attributes[VertexAttributeVN.normal.rawValue].bufferIndex = BufferIndex.meshPositions.rawValue
        
        // Interleave them
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        vertexDescriptor.layouts[0].stride = 24
        
        return vertexDescriptor
        
    }
    
}

struct Mesh {
    
    let mtkMesh: MTKMesh
    let vertexDescriptor: MTLVertexDescriptor
    
    init(name: String, meshGeometry: MeshGeometry) {
        self.mtkMesh = meshGeometry.mtkMesh
        self.mtkMesh.name = name
        self.vertexDescriptor = meshGeometry.vertexDescriptor
        self.mtkMesh.vertexBuffers[0].buffer.label = name + " Vertex Buffer"
        self.mtkMesh.submeshes[0].indexBuffer.buffer.label = name + " Index Buffer"
    }
    
    // Assigns the vertex buffer to the vertex shader arguments
    func bindToVertexShader(encoder: MTLRenderCommandEncoder) {
        encoder.setVertexBuffer(mtkMesh.vertexBuffers[0].buffer, offset: 0, index: BufferIndex.meshPositions.rawValue)
    }
    
    // Just a draw call for convenience
    func drawMesh(encoder: MTLRenderCommandEncoder) {
        encoder.drawIndexedPrimitives(type: mtkMesh.submeshes[0].primitiveType,
                                      indexCount: mtkMesh.submeshes[0].indexCount,
                                      indexType: mtkMesh.submeshes[0].indexType,
                                      indexBuffer: mtkMesh.submeshes[0].indexBuffer.buffer,
                                      indexBufferOffset: 0)
    }
    
}
