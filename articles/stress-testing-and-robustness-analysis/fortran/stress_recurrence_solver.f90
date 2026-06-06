program stress_recurrence_solver
  implicit none

  integer, parameter :: n_steps = 80
  integer :: time_index
  integer :: shock_time
  integer :: stress_duration
  logical :: stress_active

  real(8) :: demand
  real(8) :: capacity
  real(8) :: initial_capacity
  real(8) :: capacity_loss
  real(8) :: demand_growth
  real(8) :: recovery_rate
  real(8) :: unmet_demand
  real(8) :: service_ratio
  integer :: failed

  demand_growth = 0.025d0
  initial_capacity = 100.0d0
  capacity_loss = 35.0d0
  recovery_rate = 0.12d0
  shock_time = 32
  stress_duration = 14

  demand = 55.0d0
  capacity = initial_capacity

  print '(A)', 'time,demand,capacity,unmet_demand,service_ratio,failed'

  do time_index = 1, n_steps
    if (time_index > 1) then
      stress_active = time_index >= shock_time .and. time_index < shock_time + stress_duration

      demand = demand * (1.0d0 + demand_growth)

      if (time_index == shock_time) then
        capacity = max(0.0d0, capacity - capacity_loss)
      end if

      if ((.not. stress_active) .and. capacity < initial_capacity) then
        capacity = capacity + recovery_rate * (initial_capacity - capacity)
      end if

      capacity = max(0.0d0, capacity)
    end if

    unmet_demand = max(0.0d0, demand - capacity)

    if (demand <= 0.0d0) then
      service_ratio = 1.0d0
    else
      service_ratio = min(capacity / demand, 1.0d0)
    end if

    if (service_ratio < 0.85d0) then
      failed = 1
    else
      failed = 0
    end if

    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,I0)', &
      time_index, ',', demand, ',', capacity, ',', unmet_demand, ',', service_ratio, ',', failed
  end do

end program stress_recurrence_solver
