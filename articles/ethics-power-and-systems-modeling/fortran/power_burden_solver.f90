program power_burden_solver
  implicit none

  integer, parameter :: n = 7
  integer :: i
  character(len=32) :: names(n)
  real(8) :: affected(n), influence(n), benefit(n), burden(n)
  integer :: represented(n)
  real(8) :: net_benefit, burden_gap, power_burden_gap

  names = (/ &
    'public_agency                   ', &
    'technical_modelers              ', &
    'frontline_workers               ', &
    'affected_residents              ', &
    'low_access_households           ', &
    'future_generations              ', &
    'local_environment               ' /)

  affected = (/ 0.40d0, 0.20d0, 0.70d0, 0.95d0, 1.00d0, 0.90d0, 0.85d0 /)
  represented = (/ 1, 1, 1, 1, 0, 0, 0 /)
  influence = (/ 0.95d0, 0.85d0, 0.45d0, 0.35d0, 0.10d0, 0.00d0, 0.05d0 /)
  benefit = (/ 0.80d0, 0.65d0, 0.55d0, 0.50d0, 0.35d0, 0.40d0, 0.30d0 /)
  burden = (/ 0.20d0, 0.15d0, 0.35d0, 0.60d0, 0.80d0, 0.75d0, 0.70d0 /)

  print '(A)', 'group,affected,represented,influence,expected_benefit,expected_burden,net_benefit,burden_gap,power_burden_gap'

  do i = 1, n
    net_benefit = benefit(i) - burden(i)
    burden_gap = burden(i) - benefit(i)
    power_burden_gap = affected(i) * burden(i) * (1.0d0 - influence(i))

    print '(A,",",F8.6,",",I1,",",F8.6,",",F8.6,",",F8.6,",",F8.6,",",F8.6,",",F8.6)', &
      trim(names(i)), affected(i), represented(i), influence(i), benefit(i), burden(i), net_benefit, burden_gap, power_burden_gap
  end do

end program power_burden_solver
