<div align='center'>
<p>
  <a href="https://github.com/PScoriae/terraform-infra/blob/main/LICENSE.md">
    <img src="https://img.shields.io/github/license/othneildrew/Best-README-Template.svg?style=for-the-badge">
  </a>
  <a href="https://linkedin.com/in/pierreccesario">
    <img src="https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555">
  </a>
</p>
<p>
  <img src="./docs/terraform.svg" width=300>
</p>

## PCPartsTool Terraform IaC

</div>
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about">About</a>
    </li>
    <li><a href="#installation">Installation</a></li>
  </ol>
</details>
<hr/>

# About

This repository is concerned with the provisioning of infrastructure for the PCPartsTool project using Terraform IaC. Currently, the cloud services used to host PCPartsTool are AWS and Cloudflare.

**Note:** This is just one of multiple repositories that contribute to the PCPartsTool project. Here are all the related repositories:

| Repository                                                             | Built With                                                                                                                                                                                                                                                               | Description                                                         |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------- |
| [PCPartsTool](https://github.com/PScoriae/PCPartsTool)                 | [SvelteKit](https://kit.svelte.com), [TypeScript](https://www.typescriptlang.org/), [Tailwind CSS](https://tailwindcss.com), [MongoDB](https://mongodb.com), [Jenkins](https://www.jenkins.io/), [Docker](https://www.docker.com/), [Playwright](https://playwright.dev) | The SvelteKit MongoDB WebApp                                        |
| [PCPartsTool-Scraper](https://github.com/PScoriae/PCPartsTool-Scraper) | [JavaScript](https://www.javascript.com/), [Jenkins](https://www.jenkins.io/), [Docker](https://www.docker.com/)                                                                                                                                                         | Scraping Script to Gather E-commerce Item Data                      |
| [terraform-infra](https://github.com/PScoriae/terraform-infra)         | [Terraform](https://terraform.com), [Cloudflare](https://cloudflare.com), [AWS](https://aws.amazon.com)                                                                                                                                                                  | Terraform IaC for PCPartsTool Cloud Infrastructure                  |
| [ansible-ec2](https://github.com/PScoriae/ansible-ec2)                 | [Ansible](https://ansible.com), [Prometheus](https://prometheus.io), [Grafana](https://grafana.com), [Nginx](https://nginx.com), [AWS](https://aws.amazon.com)                                                                                                           | Ansible CaC for AWS EC2 Bootstraping, Observability and Maintenance |

# Installation

This section guides you on how to setup this repo for your own use.

1. First, ensure [Terraform](https://terraform.com) is installed on your dev computer.
2. Ensure the [AWS CLI](https://aws.amazon.com/cli/) is also installed on your dev computer.
3. In the AWS console, create an IAM User for Terraform to use.
4. Run the `aws configure` in your terminal to configure the AWS CLI to use said IAM User:
5. In your desired project folder, clone the project with the following command:

   ```bash
   git clone https://github.com/PScoriae/terraform-infra
   ```

6. Get your Cloudflare API token for Terraform to use.
7. Create a `variables.tf` file in the root directory of your project. It holds the credentials to your Cloudflare account. You may refer to `variables.tf.example`
8. Finally, run `terraform init` in the root directory to set up the Terraform backend.
