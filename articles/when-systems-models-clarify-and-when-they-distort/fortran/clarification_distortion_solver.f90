program clarification_distortion_solver
  implicit none

  integer, parameter :: n = 6
  integer :: i
  character(len=40) :: names(n)
  real(8) :: structural(n), dynamic(n), scenario(n), assumptions(n)
  real(8) :: false_precision(n), boundary(n), proxy(n), misuse(n)
  real(8) :: clarification, distortion, net

  names = (/ &
    'infrastructure_resilience_model       ', &
    'public_health_capacity_model          ', &
    'urban_accessibility_model             ', &
    'energy_transition_pathway_model       ', &
    'machine_learning_risk_model           ', &
    'digital_twin_operations_model         ' /)

  structural = (/ 0.85d0, 0.75d0, 0.70d0, 0.80d0, 0.45d0, 0.75d0 /)
  dynamic = (/ 0.70d0, 0.85d0, 0.50d0, 0.80d0, 0.40d0, 0.65d0 /)
  scenario = (/ 0.80d0, 0.70d0, 0.60d0, 0.85d0, 0.35d0, 0.70d0 /)
  assumptions = (/ 0.65d0, 0.60d0, 0.70d0, 0.55d0, 0.35d0, 0.50d0 /)

  false_precision = (/ 0.45d0, 0.55d0, 0.60d0, 0.50d0, 0.85d0, 0.70d0 /)
  boundary = (/ 0.65d0, 0.70d0, 0.75d0, 0.65d0, 0.70d0, 0.60d0 /)
  proxy = (/ 0.45d0, 0.55d0, 0.70d0, 0.50d0, 0.85d0, 0.50d0 /)
  misuse = (/ 0.50d0, 0.65d0, 0.55d0, 0.60d0, 0.90d0, 0.75d0 /)

  print '(A)', 'model_case,clarification_score,distortion_risk_score,net_interpretive_value'

  do i = 1, n
    clarification = 0.30d0 * structural(i) + 0.25d0 * dynamic(i) + 0.25d0 * scenario(i) + 0.20d0 * assumptions(i)
    distortion = 0.25d0 * false_precision(i) + 0.30d0 * boundary(i) + 0.20d0 * proxy(i) + 0.25d0 * misuse(i)
    net = clarification - distortion

    print '(A,",",F8.6,",",F8.6,",",F8.6)', trim(names(i)), clarification, distortion, net
  end do

end program clarification_distortion_solver
