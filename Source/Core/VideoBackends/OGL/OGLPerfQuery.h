// Copyright 2012 Dolphin Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <array>
#include <memory>

#include "Common/GL/GLExtensions/GLExtensions.h"

#include "VideoCommon/PerfQueryBase.h"

namespace OGL
{
std::unique_ptr<PerfQueryBase> GetPerfQuery(bool is_gles);

class PerfQuery : public PerfQueryBase
{
public:
  PerfQuery();
  ~PerfQuery() override {}
  void EnableQuery(PerfQueryGroup group) override;
  void DisableQuery(PerfQueryGroup group) override;
  void ResetQuery() override;
  u32 GetQueryResult(PerfQueryType type) override;
  void FlushResults() override;
  bool IsFlushed() const override;

protected:
  struct ActiveQuery
  {
    GLuint query_id;
    PerfQueryGroup query_group;
  };

  // when testing in SMS: 64 was too small, 128 was ok
  static const u32 PERF_QUERY_BUFFER_SIZE = 512;

  // This contains gl query objects with unretrieved results.
  std::array<ActiveQuery, PERF_QUERY_BUFFER_SIZE> m_query_buffer;
  u32 m_query_read_pos;

private:
  // Implementation
  std::unique_ptr<PerfQuery> m_query;
};

// Implementations
class PerfQueryGL : public PerfQuery
{
public:
  PerfQueryGL(GLenum query_type);
  ~PerfQueryGL() override;

  void EnableQuery(PerfQueryGroup group) override;
  void DisableQuery(PerfQueryGroup group) override;
  void FlushResults() override;

private:
  void WeakFlush();
  // Only use when non-empty
  void FlushOne();

  GLenum m_query_type;
};

class PerfQueryGLESNV : public PerfQuery
{
public:
  PerfQueryGLESNV();
  ~PerfQueryGLESNV() override;

  void EnableQuery(PerfQueryGroup group) override;
  void DisableQuery(PerfQueryGroup group) override;
  void FlushResults() override;

private:
  void WeakFlush();
  // Only use when non-empty
  void FlushOne();
};

}  // namespace OGL
