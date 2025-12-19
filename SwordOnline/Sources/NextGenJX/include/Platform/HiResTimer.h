#pragma once

#include <chrono>

namespace Platform
{

class HiResTimer
{
public:
    HiResTimer();

    void Tick();

    float GetDeltaTime() const; // in seconds
    float GetTotalTime() const; // in seconds

private:
    using Clock = std::chrono::high_resolution_clock;
    using TimePoint = std::chrono::time_point<Clock>;

    TimePoint m_StartTime;
    TimePoint m_LastTime;
    float m_DeltaTime;
};

} // namespace Platform
