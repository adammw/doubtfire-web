angular.module('doubtfire.tasks.task-viewer', [])

#
# Views all infomation related to a specific task including:
#  - task definition and related task sheet
#  - task submission wizard
#  - task commenter
#  - task plagiarism report
#
.directive('taskViewer', ->
  restrict: 'E'
  replace: true
  templateUrl: 'tasks/task-viewer/task-viewer.tpl.html'
  scope:
    unit: '='
    project: '='
    assessingUnitRole: '='
  controller: ($scope, $rootScope, $state, $stateParams, TaskFeedback, Task, Project, taskService, groupService, alertService, projectService, analyticsService) ->
    #
    # Active task tab group
    #
    $scope.tabs = [
      {
        title: "Task Description"
        subtitle: "A brief description of this task"
        route: 'projects#show.tasks#show.taskSheet'
        icon: "fa-info"
      }, {
        title: "Upload Submission"
        subtitle: "Upload your submission so it is ready for your tutor to mark"
        route: 'projects#show.tasks#show.taskSubmission'
        icon: "fa-upload"
      }, {
        title: "View Submission"
        subtitle: "View the latest submission you have uploaded"
        route: 'projects#show.tasks#show.viewSubmission'
        icon: "fa-file-o"
      }, {
        title: "View Comments"
        subtitle: "Write and read comments between you and your tutor"
        route: 'projects#show.tasks#show.comments'
        icon: "fa-comments-o"
      }, {
        title: "View Similarities Detected"
        subtitle: "See the other submissions and how closely they relate to your submission"
        route: 'projects#show.tasks#show.plagiarismReport'
        icon: "fa-eye"
      }
    ]

    $scope.currentState = $state.current
    $rootScope.$on '$stateChangeSuccess', () ->
      $scope.currentState = $state.current

    #
    # Sets the active tab
    #
    $scope.setActiveTab = (tab) ->
      # Do nothing if we're switching to the same tab
      return if tab is $scope.activeTab
      $scope.activeTab?.active = false
      $scope.activeTab = tab
      $scope.activeTab.active = true
      asUser = if $scope.assessingUnitRole? then $scope.assessingUnitRole.role else 'Student'
      analyticsService.event 'Student Project View - Tasks Tab', "Switched Tab as #{asUser}", "#{tab.title} Tab"

    #
    # Checks if tab is the active tab
    #
    $scope.isActiveTab = (tab) ->
      tab is $scope.activeTab

    $scope.task = _.find($scope.project.tasks, { task_definition_id: parseInt($stateParams.taskDefId) })

    unless $scope.task
      defaultTask = _.first _.sortBy($scope.project.tasks, 'seq')
      $state.go('projects#show.tasks#show', _.assign({}, $stateParams, { taskDefId: defaultTask.task_definition_id }), { location: 'replace' })

    $scope.$watch 'project.selectedTask', (newTask) ->
      unless newTask?
        newTask = _.first $scope.project.tasks
      # select initial tab
      if $stateParams.viewing == 'feedback'
        $scope.setActiveTab($scope.tabs.viewSubmission)
      else if $stateParams.viewing == 'submit'
        $scope.setActiveTab($scope.tabs.fileUpload)
      else if $scope.task?
        if $scope.task.similar_to_count > 0
          $scope.setActiveTab($scope.tabs.plagiarismReport)
        else
          switch $scope.task.status
            when 'not_started'
              $scope.setActiveTab($scope.tabs.taskSheet)
            when 'ready_to_mark', 'complete', 'discuss', 'demonstrate'
              $scope.setActiveTab($scope.tabs.viewSubmission)
            when 'fix_and_resubmit', 'working_on_it', 'need_help', 'redo'
              $scope.setActiveTab($scope.tabs.fileUpload)
            else
              $scope.setActiveTab($scope.tabs.taskSheet)
      else
        $scope.setActiveTab($scope.tabs.taskSheet)
      # Update the task grade if applicable
      $scope.taskIsGraded = taskService.taskIsGraded newTask

    #
    # Watch grade for changes
    #
    $scope.$watch 'task.grade', ->
      $scope.taskIsGraded = taskService.taskIsGraded $scope.task

    #
    # Switch the active task
    #
    $scope.setSelectedTask = (task) ->
      return if task == $scope.task
      analyticsService.event 'Student Project View', "Switched to Task", 'Task Feedback Page Dropdown'
      $state.go('projects#show.tasks#show', { taskDefId: task.task_definition_id })

    #
    # Functions from taskService to get data
    #
    $scope.statusData  = taskService.statusData
    $scope.statusClass = taskService.statusClass
    $scope.daysOverdue = taskService.daysOverdue

    $scope.daysOverdue = (task) ->
      taskService.daysOverdue(task)

    $scope.activeStatusData = ->
      $scope.statusData($scope.task)

    $scope.groupSetName = (id) ->
      groupService.groupSetName(id, $scope.unit)

    $scope.hideGroupSetName = $scope.unit.group_sets.length is 0

    $scope.recreatePDF = ->
      taskService.recreatePDF($scope.task, null)

    #
    # Statuses tutors/students may change task to
    #
    $scope.studentStatuses  = taskService.switchableStates.student
    $scope.tutorStatuses    = taskService.switchableStates.tutor
    $scope.taskEngagementConfig = {
      studentTriggers: $scope.studentStatuses.map (status) ->
        { status: status, label: taskService.statusLabels[status], iconClass: taskService.statusIcons[status], taskClass: _.trim(_.dasherize(status), '-'), helpText: taskService.helpText(status) }
      tutorTriggers: $scope.tutorStatuses.map (status) ->
        { status: status, label: taskService.statusLabels[status], iconClass: taskService.statusIcons[status], taskClass: _.trim(_.dasherize(status), '-'), helpText: taskService.helpText(status) }
      }

    $scope.activeClass = (status) ->
      if status == $scope.task.status
        "active"
      else
        ""

    $scope.triggerTransition = (status) ->
      if (status == 'ready_to_mark' || status == 'need_help') and $scope.task.definition.upload_requirements.length > 0
        $scope.setActiveTab($scope.tabs.fileUpload)
        $scope.task.status = status
        return # handle with the uploader...
      else
        taskService.updateTaskStatus($scope.unit, $scope.project, $scope.task, status)
        asUser = if $scope.assessingUnitRole? then $scope.assessingUnitRole.role else 'Student'
        analyticsService.event 'Student Project View - Tasks Tab', "Updated Status as #{asUser}", taskService.statusLabels[status]
)
