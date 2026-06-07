program panarchy_recurrence_solver
  implicit none

  integer, parameter :: n_steps = 160
  integer :: time_index
  integer :: release_event
  real(8) :: fast_cycle
  real(8) :: slow_memory
  real(8) :: fast_growth
  real(8) :: fast_capacity
  real(8) :: slow_constraint
  real(8) :: release_threshold
  real(8) :: release_magnitude
  real(8) :: revolt_strength
  real(8) :: remember_strength
  real(8) :: slow_adjustment
  real(8) :: slow_target
  character(len=16) :: phase

  fast_cycle = 0.5d0
  slow_memory = 1.0d0
  fast_growth = 0.16d0
  fast_capacity = 3.20d0
  slow_constraint = 0.08d0
  release_threshold = 2.50d0
  release_magnitude = 1.35d0
  revolt_strength = 0.14d0
  remember_strength = 0.035d0
  slow_adjustment = 0.010d0
  slow_target = 1.60d0

  print '(A)', 'time,fast_cycle,slow_memory,release_event,phase,cross_scale_coupling'

  do time_index = 1, n_steps
    release_event = 0

    if (time_index > 1) then
      fast_cycle = fast_cycle + fast_growth * fast_cycle * (1.0d0 - fast_cycle / fast_capacity) - slow_constraint * slow_memory

      if (fast_cycle > release_threshold) then
        fast_cycle = max(0.0d0, fast_cycle - release_magnitude)
        slow_memory = slow_memory + revolt_strength
        release_event = 1
      else
        slow_memory = slow_memory + slow_adjustment * (slow_target - slow_memory)
      end if

      fast_cycle = max(0.0d0, fast_cycle + remember_strength * slow_memory)
    end if

    if (release_event == 1) then
      phase = 'release'
    else if (fast_cycle < 0.8d0) then
      phase = 'reorganization'
    else if (fast_cycle < 2.0d0) then
      phase = 'growth'
    else
      phase = 'conservation'
    end if

    print '(I0,A,F12.6,A,F12.6,A,I0,A,A,A,F12.6)', &
      time_index, ',', fast_cycle, ',', slow_memory, ',', release_event, ',', trim(phase), ',', fast_cycle * slow_memory
  end do

end program panarchy_recurrence_solver
