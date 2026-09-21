output "tasks_topic_id" {
  description = "The ID of the tasks topic"
  value       = google_pubsub_topic.tasks.id
}

output "tasks_topic_name" {
  description = "The name of the tasks topic"
  value       = google_pubsub_topic.tasks.name
}

output "task_events_topic_id" {
  description = "The ID of the task-events topic"
  value       = google_pubsub_topic.task_events.id
}

output "task_events_topic_name" {
  description = "The name of the task-events topic"
  value       = google_pubsub_topic.task_events.name
}

output "dead_letter_topic_id" {
  description = "The ID of the dead-letter topic"
  value       = google_pubsub_topic.dead_letter.id
}

output "dead_letter_topic_name" {
  description = "The name of the dead-letter topic"
  value       = google_pubsub_topic.dead_letter.name
}

output "worker_push_subscription_id" {
  description = "The ID of the worker push subscription"
  value       = google_pubsub_subscription.worker_push.id
}

output "worker_push_subscription_name" {
  description = "The name of the worker push subscription"
  value       = google_pubsub_subscription.worker_push.name
}

output "dead_letter_subscription_id" {
  description = "The ID of the dead-letter pull subscription"
  value       = google_pubsub_subscription.dead_letter_pull.id
}

output "task_events_subscription_id" {
  description = "The ID of the task-events pull subscription"
  value       = google_pubsub_subscription.task_events_pull.id
}

output "pubsub_invoker_sa_email" {
  description = "The email of the Pub/Sub push invoker service account"
  value       = google_service_account.pubsub_invoker_sa.email
}
