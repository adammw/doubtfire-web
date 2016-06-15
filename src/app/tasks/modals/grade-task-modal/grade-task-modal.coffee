angular.module('doubtfire.tasks.modals.grade-task-modal', [])

#
# A modal to grade a graded task
#
.factory('GradeTaskModal', ($uibModal) ->
  GradeTaskModal = {}

  #
  # Open a grade task modal with the provided task
  #
  GradeTaskModal.show = (task) ->
    $uibModal.open
      templateUrl: 'tasks/modals/grade-task-modal/grade-task-modal.tpl.html'
      controller: 'GradeTaskModal'
      resolve:
        task: -> task

  GradeTaskModal
)
.controller('GradeTaskModal', ($scope, $uibModalInstance, gradeService, task) ->
  $scope.task = task
  $scope.data = { desiredGrade: null }
  $scope.grades = gradeService.grades
  $scope.dismiss = $uibModalInstance.dismiss
  $scope.close = ->
    $uibModalInstance.close $scope.data.desiredGrade
)
