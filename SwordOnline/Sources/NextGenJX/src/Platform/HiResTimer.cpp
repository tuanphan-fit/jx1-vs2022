#include <Platform/HiResTimer.h>

namespace Platform
{

HiResTimer::HiResTimer()
    : m_DeltaTime(0.0f)
{
    m_StartTime = Clock::now();
    m_LastTime = m_StartTime;
}

void HiResTimer::Tick()
{
    const auto now = Clock::now();
    std::chrono::duration<float> frameTime = now - m_LastTime;
    m_DeltaTime = frameTime.count();
    m_LastTime = now;
}

float HiResTimer::GetDeltaTime() const
{
    return m_DeltaTime;
}

float HiResTimer::GetTotalTime() const
{
    std::chrono::duration<float> totalTime = Clock::now() - m_StartTime;
    return totalTime.count();
}

} // namespace Platform
