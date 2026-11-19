// Copyright 2026 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

// Lets the host app copy every presented frame somewhere else (for example the
// outer display of iPhone Duo) without touching the rest of the Metal backend.

#pragma once

#ifdef __OBJC__

#import <Metal/Metal.h>

namespace Metal
{
// Called on the video thread once per presented frame, after the frame has been
// fully drawn into `backbuffer` and before the drawable is presented.
//
// `cmdbuf` is the command buffer that rendered the frame; encode extra work into it
// (it is committed right after the callback returns). Do not commit it yourself.
// (x, y, width, height) is the part of `backbuffer` that holds the game picture,
// without Dolphin's letterbox bars.
// `viewports` holds `viewport_count` rectangles (x0, y0, x1, y1, in native EFB pixels):
// the game viewports used since the previous call (see BPFunctions::TakeTrackedViewports).
//
// The callback must not block on the main thread: the main thread may be waiting
// inside SetPresentMirrorCallback for the callback to return.
using PresentMirrorCallback = void (*)(void* context, id<MTLCommandBuffer> cmdbuf,
                                       id<MTLTexture> backbuffer, int x, int y, int width,
                                       int height, const float* viewports, int viewport_count);

// Pass nullptr to remove the callback. Returns once any call in progress has finished,
// so `context` can be freed afterwards.
void SetPresentMirrorCallback(PresentMirrorCallback callback, void* context);
}  // namespace Metal

#endif
