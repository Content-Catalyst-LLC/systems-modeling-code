program des_queue_solver
  implicit none

  integer, parameter :: n_entities = 240
  integer :: entity_index
  real(8) :: arrival_rate, service_rate
  real(8) :: arrival_time(n_entities)
  real(8) :: service_time(n_entities)
  real(8) :: service_start(n_entities)
  real(8) :: departure_time(n_entities)
  real(8) :: waiting_time(n_entities)

  arrival_rate = 0.18d0
  service_rate = 0.22d0

  call random_seed()

  do entity_index = 1, n_entities
    if (entity_index == 1) then
      arrival_time(entity_index) = exponential_time(arrival_rate)
    else
      arrival_time(entity_index) = arrival_time(entity_index - 1) + exponential_time(arrival_rate)
    end if

    service_time(entity_index) = exponential_time(service_rate)
  end do

  service_start(1) = arrival_time(1)
  departure_time(1) = service_start(1) + service_time(1)
  waiting_time(1) = 0.0d0

  do entity_index = 2, n_entities
    service_start(entity_index) = max(arrival_time(entity_index), departure_time(entity_index - 1))
    departure_time(entity_index) = service_start(entity_index) + service_time(entity_index)
    waiting_time(entity_index) = service_start(entity_index) - arrival_time(entity_index)
  end do

  print '(A)', 'entity,arrival_time,service_time,service_start,departure_time,waiting_time,time_in_system'

  do entity_index = 1, n_entities
    print '(I0,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6,A,F12.6)', &
      entity_index, ',', arrival_time(entity_index), ',', service_time(entity_index), ',', &
      service_start(entity_index), ',', departure_time(entity_index), ',', waiting_time(entity_index), ',', &
      departure_time(entity_index) - arrival_time(entity_index)
  end do

contains

  real(8) function exponential_time(rate_value)
    real(8), intent(in) :: rate_value
    real(8) :: draw

    call random_number(draw)
    if (draw >= 1.0d0) draw = 0.999999999999d0
    if (draw <= 0.0d0) draw = 0.000000000001d0

    exponential_time = -log(1.0d0 - draw) / rate_value
  end function exponential_time

end program des_queue_solver
