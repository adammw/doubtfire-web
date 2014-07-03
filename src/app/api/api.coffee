angular.module("doubtfire.api", [
  "ngResource"
])

.constant("api", '/* @echo API_URL */') # Set in env.config.js

.factory("resourcePlus", ($resource, api, currentUser) ->

  (url, paramDefaults, actions) ->
    # Prefix specified relative url with API endpoint.
    url = api + url

    # Angular's default save method uses POST for both create and update, but
    # Rails expects a PUT for update. :( To handle this, we must override the
    # save method to make it POST for create and PUT for update. We also
    # expose separate create and update methods that might prove useful.
    actions = angular.extend {}, actions,
      "create": { method: "POST" }
      "update": { method: "PUT" }

    resource = $resource url, paramDefaults, actions
    delete resource["save"]

    angular.extend resource.prototype,
    $save: -> this[if this.id? then "$update" else "$create"].apply this, arguments

    return resource

)
.factory("Project", (resourcePlus) ->
  resourcePlus "/projects/:id", { id: "@id" }
)
.factory("Unit", (resourcePlus) ->
  resourcePlus "/units/:id", { id: "@id" }
)
.factory("UnitRole", (resourcePlus) ->
  resourcePlus "/unit_roles/:id", { id: "@id" }
)
.factory("UserRole", (resourcePlus) ->
  resourcePlus "/user_roles/:id", { id: "@id" }
)
.factory("Convenor", (resourcePlus) ->
  resourcePlus "/convenors"
)
.factory("Task", (resourcePlus) ->
  resourcePlus "/tasks/:id", { id: "@id" }
)
.factory("Students", (resourcePlus) ->
  resourcePlus "/students"
)
.factory("Helpdesk", (resourcePlus) ->
  resourcePlus "/helpdesk/schedule"
)






