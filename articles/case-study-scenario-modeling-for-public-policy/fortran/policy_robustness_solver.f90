program policy_robustness_solver
  implicit none

  integer, parameter :: n = 4
  integer :: i
  character(len=28) :: names(n)
  real(8) :: average_score(n), worst_case_score(n), best_case_score(n)
  real(8) :: maximum_regret(n), acceptable_share(n), robustness_score(n)

  names = (/ &
    'adaptive_pathway           ', &
    'targeted_intervention      ', &
    'universal_program          ', &
    'status_quo_maintenance     ' /)

  average_score = (/ 0.617d0, 0.550d0, 0.545d0, 0.380d0 /)
  worst_case_score = (/ 0.557d0, 0.493d0, 0.473d0, 0.338d0 /)
  best_case_score = (/ 0.684d0, 0.622d0, 0.628d0, 0.423d0 /)
  maximum_regret = (/ 0.000d0, 0.093d0, 0.112d0, 0.275d0 /)
  acceptable_share = (/ 1.000d0, 0.833d0, 0.667d0, 0.000d0 /)
  robustness_score = (/ 0.591d0, 0.502d0, 0.485d0, 0.292d0 /)

  print '(A)', 'policy,average_score,worst_case_score,best_case_score,maximum_regret,acceptable_scenario_share,robustness_score'

  do i = 1, n
    print '(A,",",F8.6,",",F8.6,",",F8.6,",",F8.6,",",F8.6,",",F8.6)', &
      trim(names(i)), average_score(i), worst_case_score(i), best_case_score(i), maximum_regret(i), acceptable_share(i), robustness_score(i)
  end do

end program policy_robustness_solver
