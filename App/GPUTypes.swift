//
//  GPUTypes.swift
//  TalkingHead-OSX
//
//  Created by Uli Held on 16.08.16.
//  Copyright © 2016 Uli Held. All rights reserved.
//

import SceneKit

struct GPUMaterial {
  let color: vector_float3
  let prop: vector_float3
}

struct GPULight {
  let position: vector_float3
  let directColor: vector_float3
  let ambientColor: vector_float3
}

struct GPUCamera {
  let position: vector_float3
}