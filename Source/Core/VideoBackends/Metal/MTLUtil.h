// Copyright 2022 Dolphin Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <Metal/Metal.h>
#include <vector>

#include "VideoBackends/Metal/MRCHelpers.h"

#include "VideoCommon/AbstractShader.h"
#include "VideoCommon/TextureConfig.h"
#include "VideoCommon/VideoConfig.h"

namespace Metal
{
struct DeviceFeatures
{
  bool subgroup_ops;
};

extern DeviceFeatures g_features;

namespace Util
{
struct Viewport
{
  float x;
  float y;
  float width;
  float height;
  float near_depth;
  float far_depth;
};

/// Gets the list of Metal devices, ordered so the system default device is first
std::vector<MRCOwned<id<MTLDevice>>> GetAdapterList();
void PopulateBackendInfo(VideoConfig* config);
void PopulateBackendInfoAdapters(VideoConfig* config,
                                 const std::vector<MRCOwned<id<MTLDevice>>>& adapters);
void PopulateBackendInfoFeatures(VideoConfig* config, id<MTLDevice> device);

AbstractTextureFormat ToAbstract(MTLPixelFormat format);
MTLPixelFormat FromAbstract(AbstractTextureFormat format);
static inline bool HasStencil(AbstractTextureFormat format)
{
  return format == AbstractTextureFormat::D24_S8 || format == AbstractTextureFormat::D32F_S8;
}

std::optional<std::string> TranslateShaderToMSL(ShaderStage stage, std::string_view source);

}  // namespace Util
}  // namespace Metal
