program calibration_validation_solver
  implicit none

  integer, parameter :: n_steps = 80
  integer, parameter :: train_cutoff = 52
  integer :: time_index

  real(8) :: growth_rate
  real(8) :: carrying_capacity
  real(8) :: state(n_steps)
  character(len=12) :: dataset

  growth_rate = 0.095d0
  carrying_capacity = 120.0d0

  state = 0.0d0
  state(1) = 10.0d0

  do time_index = 2, n_steps
    state(time_index) = state(time_index - 1) + &
      growth_rate * state(time_index - 1) * (1.0d0 - state(time_index - 1) / carrying_capacity)

    state(time_index) = max(0.0d0, state(time_index))
  end do

  print '(A)', 'time,dataset,state,growth_rate,carrying_capacity'

  do time_index = 1, n_steps
    if (time_index <= train_cutoff) then
      dataset = 'calibration'
    else
      dataset = 'validation'
    end if

    print '(I0,A,A,A,F12.6,A,F12.6,A,F12.6)', &
      time_index, ',', trim(dataset), ',', state(time_index), ',', growth_rate, ',', carrying_capacity
  end do

end program calibration_validation_solver
