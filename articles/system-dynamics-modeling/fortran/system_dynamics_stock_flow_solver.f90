program system_dynamics_stock_flow_solver
  implicit none

  integer, parameter :: periods = 160
  integer, parameter :: history_size = 200
  integer :: time, delayed_index
  real(8) :: stock(history_size)
  real(8) :: current, delayed_stock, inflow, outflow
  real(8) :: threshold_penalty, shock, next_stock
  real(8) :: growth_rate, balancing_strength, target
  real(8) :: capacity, threshold, threshold_correction, shock_size
  integer :: delay, shock_time

  stock = 0.0d0
  stock(1) = 20.0d0

  growth_rate = 0.090d0
  balancing_strength = 0.055d0
  target = 62.0d0
  delay = 7
  capacity = 100.0d0
  threshold = 82.0d0
  threshold_correction = 0.040d0
  shock_time = 95
  shock_size = -10.0d0

  print '(A)', 'time,stock,delayed_stock,inflow,outflow,threshold_penalty,shock,next_stock'

  do time = 0, periods
    current = stock(time + 1)
    delayed_index = time + 1 - delay
    if (delayed_index < 1) delayed_index = 1

    delayed_stock = stock(delayed_index)
    inflow = growth_rate * current * (1.0d0 - current / capacity)
    outflow = balancing_strength * max(delayed_stock - target, 0.0d0)

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

    next_stock = max(0.0d0, min(250.0d0, current + inflow - outflow - threshold_penalty + shock))

    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6)', &
      time, ',', current, ',', delayed_stock, ',', inflow, ',', outflow, ',', threshold_penalty, ',', shock, ',', next_stock

    if (time + 2 <= history_size) then
      stock(time + 2) = next_stock
    end if
  end do

end program system_dynamics_stock_flow_solver
