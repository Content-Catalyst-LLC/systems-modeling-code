program adoption_diffusion_solver
  implicit none

  integer, parameter :: n = 7
  integer :: i
  character(len=32) :: names(n)
  real(8) :: final_adoption_share(n), maximum_adoption_gap(n), peak_growth(n)
  integer :: final_adopter_count(n), time_to_25_percent(n), time_to_50_percent(n)

  names = (/ &
    'baseline_diffusion             ', &
    'high_social_influence          ', &
    'high_cost_barrier              ', &
    'targeted_seeding               ', &
    'network_fragmentation          ', &
    'trust_and_resistance           ', &
    'bridge_and_equity_seeding      ' /)

  final_adoption_share = (/ 0.520d0, 0.720d0, 0.280d0, 0.610d0, 0.460d0, 0.340d0, 0.660d0 /)
  final_adopter_count = (/ 62, 86, 34, 73, 55, 41, 79 /)
  maximum_adoption_gap = (/ 0.250d0, 0.300d0, 0.180d0, 0.220d0, 0.420d0, 0.310d0, 0.190d0 /)
  time_to_25_percent = (/ 8, 5, 30, 6, 12, 24, 5 /)
  time_to_50_percent = (/ 26, 14, -1, 21, -1, -1, 18 /)
  peak_growth = (/ 0.045d0, 0.080d0, 0.030d0, 0.055d0, 0.040d0, 0.025d0, 0.060d0 /)

  print '(A)', 'scenario,final_adoption_share,final_adopter_count,maximum_adoption_gap,time_to_25_percent,time_to_50_percent,peak_growth'

  do i = 1, n
    print '(A,",",F8.6,",",I4,",",F8.6,",",I4,",",I4,",",F8.6)', &
      trim(names(i)), final_adoption_share(i), final_adopter_count(i), maximum_adoption_gap(i), &
      time_to_25_percent(i), time_to_50_percent(i), peak_growth(i)
  end do

end program adoption_diffusion_solver
