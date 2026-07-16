
resource "datadog_monitor" "web_cpu_high" {
  name    = "High CPU on Web Tier - ${title(var.env)}"
  type    = "metric alert"
  message = "Web Tier CPU is above 80% on {{host.name}}. @pagerduty-infrastructure"
  
  query   = "avg(last_5m):avg:system.cpu.user{environment:${var.env},host:vmss-web-*} by {host} > 80"

  monitor_thresholds {
    critical          = 80
    warning           = 70
    critical_recovery = 60
    warning_recovery  = 55
  }
}

resource "datadog_monitor" "app_cpu_high" {
  name    = "High CPU on App Tier - ${title(var.env)}"
  type    = "metric alert"
  message = "App Tier CPU is above 80% on {{host.name}}. Check backend logs. @pagerduty-infrastructure"
  
  query   = "avg(last_5m):avg:system.cpu.user{environment:${var.env},host:vmss-app-*} by {host} > 80"

  monitor_thresholds {
    critical          = 80
    warning           = 70
    critical_recovery = 60
    warning_recovery  = 55
  }
}

resource "datadog_monitor" "postgres_cpu_high" {
  name    = "High CPU on PostgreSQL - ${title(var.env)}"
  type    = "metric alert"
  message = "Database CPU is dangerously high on ${var.postgres_name}. @pagerduty-database"
  
  query   = "avg(last_5m):avg:azure.dbforpostgresql_flexibleservers.cpu_percent{server:${var.postgres_name}} > 80"

  monitor_thresholds {
    critical          = 80
    warning           = 70
    critical_recovery = 60
    warning_recovery  = 55
  }
}


resource "datadog_dashboard" "infrastructure_overview" {
  title       = "Infrastructure Dashboard (${title(var.env)})"
  description = "Server, Container, and Database metrics"
  layout_type = "ordered"

  widget {
    timeseries_definition {
      title = "Web Tier CPU Utilization"
      request {
        q            = "avg:system.cpu.user{environment:${var.env},host:vmss-web-*} by {host}"
        display_type = "line"
      }
    }
  }

  widget {
    timeseries_definition {
      title = "App Tier CPU Utilization"
      request {
        q            = "avg:system.cpu.user{environment:${var.env},host:vmss-app-*} by {host}"
        display_type = "line"
      }
    }
  }

  widget {
    timeseries_definition {
      title = "Database CPU: ${var.postgres_name}"
      request {
        q            = "avg:azure.dbforpostgresql_flexibleservers.cpu_percent{server:${var.postgres_name}}"
        display_type = "line"
      }
    }
  }
  
  widget {
    query_value_definition {
      title = "Web VMSS Azure Resource ID"
      request {
        q = "'${var.web_vmss_id}'"
      }
      custom_links {
        label = "Open in Azure Portal"
        link  = "https://portal.azure.com/#resource${var.web_vmss_id}"
      }
    }
  }

  widget {
    query_value_definition {
      title = "App VMSS Azure Resource ID"
      request {
        q = "'${var.app_vmss_id}'"
      }
      custom_links {
        label = "Open in Azure Portal"
        link  = "https://portal.azure.com/#resource${var.app_vmss_id}"
      }
    }
  }
}