// Copyright 2023 DolphiniOS Project
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

void DOLHostQueueRunSync(void (^block)(void));
void DOLHostQueueRunAsync(void (^block)(void));
