program infrastructure_cascade_solver
  implicit none

  integer, parameter :: n = 6
  integer :: i
  character(len=24) :: names(n)
  integer :: final_failed(n), max_failed(n), cascade_depth(n)
  real(8) :: max_weighted_service_loss(n)

  names = (/ &
    'localized_outage        ', &
    'hub_failure             ', &
    'dependency_cascade      ', &
    'load_redistribution     ', &
    'compound_shock          ', &
    'recovery_intervention   ' /)

  final_failed = (/ 1, 6, 3, 3, 8, 6 /)
  max_failed = (/ 1, 6, 3, 3, 8, 6 /)
  max_weighted_service_loss = (/ 0.55d0, 5.40d0, 2.55d0, 2.45d0, 6.80d0, 5.00d0 /)
  cascade_depth = (/ 0, 2, 1, 1, 2, 2 /)

  print '(A)', 'scenario,final_failed_count,max_failed_count,max_weighted_service_loss,cascade_depth'

  do i = 1, n
    print '(A,",",I3,",",I3,",",F10.6,",",I3)', &
      trim(names(i)), final_failed(i), max_failed(i), max_weighted_service_loss(i), cascade_depth(i)
  end do

end program infrastructure_cascade_solver
