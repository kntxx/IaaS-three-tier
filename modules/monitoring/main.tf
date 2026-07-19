
resource "datadog_monitor" "web_cpu_high" {
  name    = "High CPU on Web Tier - ${title(var.env)}"
  type    = "metric alert"
  message = "Web Tier CPU is above 80% on {{host.name}}. @gesorokent@gmail.com"
  
  query   = "avg(last_5m):avg:system.cpu.user{host:vmss-web-*} by {host} > 80"

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
  message = "App Tier CPU is above 80% on {{host.name}}. @gesorokent@gmail.com"
  
  query   = "avg(last_5m):avg:system.cpu.user{host:vmss-app-*} by {host} > 80"

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
        q            = "avg:system.cpu.user{host:vmss-web-*} by {host}"
        display_type = "line"
      }
    }
  }

  widget {
    timeseries_definition {
      title = "App Tier CPU Utilization"
      request {
        q            = "avg:system.cpu.user{host:vmss-app-*} by {host}"
        display_type = "line"
      }
    }
  }

  
  widget {
  note_definition {
    content           = "**Web VMSS**\n[Open in Azure Portal](https://portal.azure.com/#resource${var.web_vmss_id})"
    background_color  = "white"
  }
}


  widget {
  note_definition {
    content           = "**App VMSS**\n[Open in Azure Portal](https://portal.azure.com/#resource${var.app_vmss_id})"
    background_color  = "white"
  }
}
}