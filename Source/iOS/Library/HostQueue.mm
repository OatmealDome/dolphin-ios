// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#include "HostQueue.h"

#include <dispatch/dispatch.h>

#include "Core/Core.h"

static dispatch_queue_t s_host_queue;
static dispatch_once_t s_host_queue_once;

dispatch_queue_t DOLHostQueueGetUnderlyingQueue()
{
  dispatch_once(&s_host_queue_once, ^{
    s_host_queue = dispatch_queue_create("me.oatmealdome.DolphiniOS.host-queue", DISPATCH_QUEUE_SERIAL);
  });

  return s_host_queue;
}

void DOLHostQueueExecuteBlock(void (^block)(void))
{
  Core::DeclareAsHostThread();

  block();

  Core::UndeclareAsHostThread();
}

void DOLHostQueueRunSync(void (^block)(void))
{
  dispatch_sync(DOLHostQueueGetUnderlyingQueue(), ^{
    DOLHostQueueExecuteBlock(block);
  });
}

void DOLHostQueueRunAsync(void (^block)(void))
{
  dispatch_async(DOLHostQueueGetUnderlyingQueue(), ^{
    DOLHostQueueExecuteBlock(block);
  });
}
