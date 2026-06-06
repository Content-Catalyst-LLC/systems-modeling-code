program delayed_feedback_solver
  implicit none

  integer, parameter :: periods = 160
  integer, parameter :: history_size = 200
  integer :: time, delayed_index
  real(8) :: state(history_size)
  real(8) :: current, delayed_state, inflow
  real(8) :: balancing_outflow, threshold_penalty
  real(8) :: shock, next_state
  real(8) :: growth_rate, balancing_strength, target
  real(8) :: threshold, threshold_correction, shock_size
  integer :: delay, shock_time

  state = 0.0d0
  state(1) = 12.0d0

  growth_rate = 0.080d0
  balancing_strength = 0.060d0
  target = 50.0d0
  delay = 7
  threshold = 85.0d0
  threshold_correction = 0.035d0
  shock_time = 70
  shock_size = -10.0d0

  print '(A)', 'time,state,delayed_state,inflow,balancing_outflow,threshold_penalty,shock,next_state'

  do time = 0, periods
    current = state(time + 1)
    delayed_index = time + 1 - delay
    if (delayed_index < 1) delayed_index = 1

    delayed_state = state(delayed_index)
    inflow = growth_rate * current
    balancing_outflow = balancing_strength * max(delayed_state - target, 0.0d0)

    if (current >= threshold) then
      threshold_penalty = threshold_correction * (current - threshold)
    else
      threshold_penalty = 0.0d0
    end if

    if (time == shock_time) then
      shock = shock_size
    else
      shock = 0.0d0
    end if

    next_state = max(0.0d0, min(250.0d0, current + inflow - balancing_outflow - threshold_penalty + shock))

    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6)', &
      time, ',', current, ',', delayed_state, ',', inflow, ',', balancing_outflow, ',', threshold_penalty, ',', shock, ',', next_state

    if (time + 2 <= history_size) then
      state(time + 2) = next_state
    end if
  end do

end program delayed_feedback_solver
