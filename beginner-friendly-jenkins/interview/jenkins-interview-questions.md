# Jenkins Interview Questions (Simple Answers)

## Beginner
1. What is Jenkins?
A tool that automates build, test, and deploy.

2. What is CI?
Automatic checking of every code change.

3. What is CD?
Automatic safe delivery after checks pass.

4. Controller vs agent?
Controller manages; agent does work.

5. What is Jenkinsfile?
Pipeline recipe file in code.

## Intermediate
6. Why pipeline as code?
Version control, review, repeatability.

7. How do you keep secrets safe?
Use Jenkins Credentials, never hardcode secrets.

8. What is multibranch pipeline?
Auto pipeline per branch and pull request.

9. What is quality gate?
Stop pipeline when quality/security rules fail.

10. How do you rollback release?
Deploy last known good artifact quickly.

## Advanced
11. What is JCasC?
Jenkins configuration in yaml as code.

12. How do you scale Jenkins?
Use more agents, keep controller light, monitor queues.

13. How do you secure Jenkins in production?
HTTPS, RBAC, least privilege, patch updates, audits.

14. How do you handle flaky builds?
Standardize environments, isolate flaky tests, fix root causes.

15. What metrics do you monitor?
Success rate, duration, queue time, agent health, deploy health.
