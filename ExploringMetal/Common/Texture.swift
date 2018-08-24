//
//  Texture.swift
//  ExploringMetal
//
//  Created by Adil Patel on 08/08/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

import Foundation
import Metal
import MetalKit

enum TextureErrors: Error {
    case badPath
}

struct Texture {
    
    var texture: MTLTexture?
    
    init(name: String,
         file: String,
         createMipMaps: Bool,
         textureStorage: MTLStorageMode,
         usage: MTLTextureUsage,
         cpuCacheMode: MTLCPUCacheMode,
         device: MTLDevice) {
        
        // Take care of all the texture creation options here...
        let mipMapCreation = NSNumber(value: createMipMaps)
        let storageMode  = NSNumber(value: textureStorage.rawValue)
        let textureUsage = NSNumber(value: usage.rawValue)
        let textureCPUCacheMode = NSNumber(value: cpuCacheMode.rawValue)
        let allocateMipMaps = NSNumber(value: createMipMaps)
        
        let options = [MTKTextureLoader.Option.generateMipmaps     : mipMapCreation,
                       MTKTextureLoader.Option.textureStorageMode  : storageMode,
                       MTKTextureLoader.Option.textureUsage        : textureUsage,
                       MTKTextureLoader.Option.textureCPUCacheMode : textureCPUCacheMode,
                       MTKTextureLoader.Option.allocateMipmaps     : allocateMipMaps]
        
        // Now we create the actual texture
        let textureLoader = MTKTextureLoader(device: device)
        
        // Start by loading the file
        let separated = file.components(separatedBy: ".")
        guard let url = Bundle.main.url(forResource: separated[0], withExtension: separated[1]) else {
            print("ERROR: Failed to load \(file)!")
            return
        }
        do {
            try texture = textureLoader.newTexture(URL: url, options: options)
            texture?.label = name
        } catch {
            print("ERROR: Failed to create texture with error: \(error)")
        }
        
    }
    
    
    // As the names suggest, we call these when encoding commands
    func bindToVertexShader(encoder: MTLRenderCommandEncoder, index: Int) {
        encoder.setVertexTexture(texture, index: index)
    }
    
    func bindToFragmentShader(encoder: MTLRenderCommandEncoder, index: Int) {
        encoder.setFragmentTexture(texture, index: index)
    }
    
    func bindToComputeShader(encoder: MTLComputeCommandEncoder, index: Int) {
        encoder.setTexture(texture, index: index)
    }
    
}

struct Sampler {
    
    // This is really just straightforward
    let samplerState: MTLSamplerState?
    
    init(descriptor: MTLSamplerDescriptor, device: MTLDevice) {
        samplerState = device.makeSamplerState(descriptor: descriptor)
    }
    
    func bindToVertexShader(encoder: MTLRenderCommandEncoder, index: Int) {
        encoder.setVertexSamplerState(samplerState, index: index)
    }
    
    func bindToFragmentShader(encoder: MTLRenderCommandEncoder, index: Int) {
        encoder.setFragmentSamplerState(samplerState, index: index)
        
    }
    
    func bindToComputeShader(encoder: MTLComputeCommandEncoder, index: Int) {
        encoder.setSamplerState(samplerState, index: index)
    }
    
}

func createSamplerDescriptor() -> MTLSamplerDescriptor {
    // Configure the sampler
    let samplerDescriptor = MTLSamplerDescriptor()
    samplerDescriptor.sAddressMode = .repeat
    samplerDescriptor.tAddressMode = .repeat
    samplerDescriptor.minFilter = .linear
    samplerDescriptor.magFilter = .linear
    samplerDescriptor.mipFilter = .linear
    samplerDescriptor.label = "Texture Sampler"
    return samplerDescriptor
}


