# Transferables - Pipeline & Setup Documentation

This folder contains reusable CI/CD pipeline and setup documentation that can be transferred/ported to other iOS projects.

## What's Inside

These documents provide comprehensive guides for setting up the entire CI/CD pipeline used in this project:

### Quick Reference
- **[QUICK_START_PIPELINE.md](QUICK_START_PIPELINE.md)** - ⚡ Fast 10-step checklist to port the pipeline to a new app

### Comprehensive Guides
- **[PIPELINE_SETUP_GUIDE.md](PIPELINE_SETUP_GUIDE.md)** - 🚀 Complete step-by-step CI/CD setup and porting guide
- **[SECRETS_REFERENCE.md](SECRETS_REFERENCE.md)** - 🔐 All secrets, environment variables, and how to obtain them
- **[PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md)** - 📊 Visual diagrams and architecture overview

## Purpose

These documents are designed to be **transferable** - they can be used as templates or guides when:
- Setting up CI/CD for a new iOS project
- Migrating an existing project to this pipeline architecture
- Understanding the complete build and deployment flow
- Training team members on the deployment process

## Technology Stack Covered

- **XcodeGen** - Project file generation
- **Fastlane** - Build automation and TestFlight deployment
- **Fastlane Match** - Code signing management
- **GitHub Actions** - CI/CD execution
- **App Store Connect** - Distribution and submission

## Getting Started

If you're porting this pipeline to a new project, start with **[QUICK_START_PIPELINE.md](QUICK_START_PIPELINE.md)** for a condensed checklist, then refer to the other documents as needed for detailed explanations.
