variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "environment" {
  description = "The deployment environment (dev, staging, prod)"
  type        = string
}

variable "tasks_topic_name" {
  description = "Name of the tasks topic. If omitted, defaults to <environment>-tasks"
  type        = string
  default     = null
}

variable "task_events_topic_name" {
  description = "Name of the task-events topic. If omitted, defaults to <environment>-task-events"
  type        = string
  default     = null
}

variable "dead_letter_topic_name" {
  description = "Name of the dead-letter topic. If omitted, defaults to <environment>-dead-letter-topic"
  type        = string
  default     = null
}

variable "worker_push_endpoint" {
  description = "The HTTPS push endpoint URL on the worker service (e.g. https://worker-xyz.a.run.app/events/push)"
  type        = string
}

variable "worker_service_name" {
  description = "Cloud Run service name of the worker (used to bind roles/run.invoker to the Pub/Sub invoker SA)"
  type        = string
  default     = null
}
