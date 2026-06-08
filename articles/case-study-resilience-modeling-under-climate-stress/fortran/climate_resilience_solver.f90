program climate_resilience_solver
  implicit none

  integer, parameter :: n = 6
  integer :: i
  character(len=36) :: names(n)
  real(8) :: average_service(n), minimum_service(n), final_capacity(n), final_degradation(n), resilience_score(n)
  integer :: time_below_threshold(n), threshold_crossings(n), transformed(n)

  names = (/ &
    'targeted_resilience_investment    ', &
    'moderate_climate_stress           ', &
    'transformation_pathway            ', &
    'repeated_shocks                   ', &
    'delayed_adaptation                ', &
    'compound_climate_stress           ' /)

  average_service = (/ 0.720d0, 0.690d0, 0.610d0, 0.590d0, 0.550d0, 0.490d0 /)
  minimum_service = (/ 0.590d0, 0.560d0, 0.520d0, 0.480d0, 0.430d0, 0.360d0 /)
  time_below_threshold = (/ 0, 0, 5, 9, 14, 24 /)
  threshold_crossings = (/ 0, 0, 2, 3, 4, 5 /)
  final_capacity = (/ 0.870d0, 0.720d0, 0.760d0, 0.610d0, 0.600d0, 0.500d0 /)
  final_degradation = (/ 0.060d0, 0.080d0, 0.170d0, 0.160d0, 0.210d0, 0.300d0 /)
  transformed = (/ 0, 0, 1, 0, 0, 0 /)
  resilience_score = (/ 0.699d0, 0.662d0, 0.476d0, 0.399d0, 0.2665d0, 0.025d0 /)

  print '(A)', 'scenario,average_service,minimum_service,time_below_threshold,threshold_crossings,final_adaptive_capacity,final_degradation,transformed,resilience_score'

  do i = 1, n
    print '(A,",",F8.6,",",F8.6,",",I4,",",I4,",",F8.6,",",F8.6,",",I2,",",F8.6)', &
      trim(names(i)), average_service(i), minimum_service(i), time_below_threshold(i), threshold_crossings(i), &
      final_capacity(i), final_degradation(i), transformed(i), resilience_score(i)
  end do

end program climate_resilience_solver
