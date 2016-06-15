angular.module('doubtfire.projects.states.show', [])

#
# Default state for a new project
#
.config((headerServiceProvider, $stateProvider) ->
  projectsShowStateData =
    url: "/projects/:projectId?unitRole"
    redirectTo: 'projects#show.progress'
    views:
      main:
        controller: "ProjectsShowCtrl"
        templateUrl: "projects/states/show/show.tpl.html"
    data:
      pageTitle: "_Home_"
      roleWhitelist: ['Student', 'Tutor', 'Convenor', 'Admin']
  headerServiceProvider.state "projects#show", projectsShowStateData
  $stateProvider
    .state('projects#show.progress', {
      url: '/progress'
      views:
        project:
          template: '<project-progress-dashboard></project-progress-dashboard>'
    })
    .state('projects#show.tasks', {
      url: '/tasks'
      views:
        project:
          template: '<task-viewer unit="unit" project="project" assessing-unit-role="assessingUnitRole"></task-viewer>'
    })
    .state('projects#show.tasks#show', {
      url: '/tasks/:taskDefId'
      redirectTo: 'projects#show.tasks#show.taskSheet'
      views:
        project:
          template: '<task-viewer unit="unit" project="project" assessing-unit-role="assessingUnitRole"></task-viewer>'
    })
    .state('projects#show.tasks#show.taskSheet', {
      url: '/description'
      title: "Task Description"
      subtitle: "A brief description of this task"
      views:
        task:
          template: '<task-sheet-viewer task="task" project="project" unit="unit"></task-sheet-viewer>'
    })
    .state('projects#show.tasks#show.taskSubmission', {
      url: '/upload'
      title: "Upload Submission"
      subtitle: "Upload your submission so it is ready for your tutor to mark"
      views:
        task:
          template: '<task-submission-wizard task="task" project="project" unit="unit" assessing-unit-role="assessingUnitRole"></task-submission-wizard>'
    })
    .state('projects#show.tasks#show.viewSubmission', {
      url: '/submission'
      title: "View Submission"
      subtitle: "View the latest submission you have uploaded"
      views:
        task:
          template: '<task-submission-viewer project="project" task="task"></task-submission-viewer>'
    })
    .state('projects#show.tasks#show.comments', {
      url: '/comments'
      title: "View Comments"
      subtitle: "Write and read comments between you and your tutor"
      views:
        task:
          template: '<task-comments-viewer project="project" task="task"></task-comments-viewer>'
    })
    .state('projects#show.tasks#show.plagiarismReport', {
      url: '/similarities'
      title: "View Similarities Detected"
      subtitle: "See the other submissions and how closely they relate to your submission"
      views:
        task:
          template: '<task-plagiarism-report-viewer task="task"></task-plagiarism-report-viewer>'
    })
    .state('projects#show.tutorials', {
      url: '/tutorials'
      views:
        project:
          template: '<project-lab-list></project-lab-list>'
    })
    .state('projects#show.groups', {
      url: '/groups'
      views:
        project:
          template: '<student-group-manager></student-group-manager>'
    })
    .state('projects#show.learning_outcome', {
      url: '/learning_outcome'
      views:
        project:
          template: '<project-outcome-alignment></project-outcome-alignment>'
    })
    .state('projects#show.portfolio', {
      url: '/portfolio'
      views:
        project:
          template: '<project-portfolio-wizard project="project"></project-portfolio-wizard>'
    })

)

.controller("ProjectsShowCtrl", ($scope, $stateParams, currentUser, UnitRole, Project, projectService, alertService, analyticsService) ->
  analyticsService.event 'Student Project View', 'Started Viewing Project'

  if $stateParams.authToken?
    # $scope.message = $stateParams.authToken
    currentUser.authenticationToken = $stateParams.authToken

  # Provided show task id
  if $stateParams.showTaskId?
    $scope.showTaskId = parseInt($stateParams.showTaskId, 10)

  $scope.unitRole = $stateParams.unitRole

  if $scope.unitRole?
    # Bound to inner-directive
    UnitRole.get { id: $scope.unitRole },
      (response) ->
        $scope.assessingUnitRole = response
      (error) ->
        $scope.assessingUnitRole = null
        $scope.unitRole = null
  else
    $scope.assessingUnitRole = null

  # Bound to inner-directive
  $scope.project = { project_id: $stateParams.projectId }

  # Bound to inner-directive
  $scope.unit = null

  #
  # Batch Discuss button
  #
  $scope.transitionWeekEnd = () ->
    # Reject if there is no project
    return unless $scope.project?
    Project.update(
      { id: $scope.project.project_id, trigger: "trigger_week_end" }
      (project) ->
        projectService.updateTaskStats($scope.project, project.stats)
        # Update the task stats
        _.each $scope.project.tasks, (task) =>
          task.status = _.filter(project.tasks, { task_definition_id: task.task_definition_id })[0].status
        alertService.add("success", "Status updated.", 2000)
        analyticsService.event 'Student Project View', "Transitioned Week End"
      (response) -> alertService.add("danger", response.data.error, 6000)
    )
)
