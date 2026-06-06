program historical_stock_flow_solver
  implicit none

  integer, parameter :: n_steps = 160
  integer, parameter :: history_size = 200
  integer :: time, delayed_index
  real(8) :: exponential(history_size)
  real(8) :: logistic(history_size)
  real(8) :: delayed_feedback(history_size)
  real(8) :: current_exponential, current_logistic, current_delayed
  real(8) :: delayed_state, inflow, outflow, shock
  real(8) :: growth_rate, carrying_capacity, balancing_strength
  real(8) :: target, shock_size
  integer :: delay, shock_time

  exponential = 0.0d0
  logistic = 0.0d0
  delayed_feedback = 0.0d0

  exponential(1) = 10.0d0
  logistic(1) = 10.0d0
  delayed_feedback(1) = 10.0d0

  growth_rate = 0.080d0
  carrying_capacity = 80.0d0
  balancing_strength = 0.060d0
  target = 55.0d0
  delay = 7
  shock_time = 90
  shock_size = -8.0d0

  print '(A)', 'time,exponential,logistic,delayed_feedback,delayed_state,inflow,outflow,shock'

  do time = 0, n_steps
    current_exponential = exponential(time + 1)
    current_logistic = logistic(time + 1)
    current_delayed = delayed_feedback(time + 1)

    delayed_index = time + 1 - delay
    if (delayed_index < 1) delayed_index = 1

    delayed_state = delayed_feedback(delayed_index)
    inflow = growth_rate * current_delayed
    outflow = balancing_strength * max(delayed_state - target, 0.0d0)

    if (time == shock_time) then
      shock = shock_size
    else
      shock = 0.0d0
    end if

    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6)', &
      time, ',', current_exponential, ',', current_logistic, ',', current_delayed, ',', delayed_state, ',', inflow, ',', outflow, ',', shock

    if (time + 2 <= history_size) then
      exponential(time + 2) = min(250.0d0, max(0.0d0, current_exponential + growth_rate * current_exponential))
      logistic(time + 2) = min(250.0d0, max(0.0d0, current_logistic + growth_rate * current_logistic * (1.0d0 - current_logistic / carrying_capacity)))
      delayed_feedback(time + 2) = min(250.0d0, max(0.0d0, current_delayed + inflow - outflow + shock))
    end if
  end do

end program historical_stock_flow_solver
