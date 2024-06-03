variable region {
  description = "AWS Region"
  type        = string
}

variable environment {
  description = "Environment name. There will for tags, names of almost each resources"
  type        = string
}

variable application {
  description = "Application name"
  type        = string
}

variable infrastructure {
  default = {}
  description = <<EOT
    
  }
EOT
}

variable eks {
  default = {}
  description = <<EOT
    
  }
EOT
}