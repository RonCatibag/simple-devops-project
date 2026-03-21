import { Component, signal } from '@angular/core';

@Component({
  selector: 'app-root',
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App {
  protected readonly title = signal('Ronald Catibag | DevOps Engineer');
  protected readonly mobileMenuOpen = signal(false);

  protected readonly personalInfo = [
    { label: 'Name', value: 'Ronald Catibag' },
    { label: 'Role', value: 'DevOps Engineer' },
    { label: 'Location', value: 'Caloocan, Metro Manila, Philippines' },
    { label: 'Focus', value: 'Cloud Infrastructure, CI/CD, Automation' },
    { label: 'Interests', value: 'IaC, Containerization, Platform Engineering' },
  ];

  protected readonly skillCategories = [
    {
      name: 'Cloud & Infrastructure',
      icon: 'cloud',
      skills: ['AWS (EC2, RDS, S3, Lambda, IAM)', 'Terraform', 'Packer', 'Infrastructure as Code'],
    },
    {
      name: 'CI/CD & Automation',
      icon: 'rocket',
      skills: ['Jenkins', 'GitLab CI', 'Ansible', 'Octopus Deploy'],
    },
    {
      name: 'Containers & Orchestration',
      icon: 'box',
      skills: ['Docker', 'Kubernetes', 'Amazon ECS', 'Helm'],
    },
    {
      name: 'Monitoring & Observability',
      icon: 'chart',
      skills: ['Prometheus', 'Kibana', 'ELK Stack', 'Grafana'],
    },
    {
      name: 'Programming',
      icon: 'code',
      skills: ['Python', 'Bash', 'C++', 'TypeScript'],
    },
    {
      name: 'Systems & Networking',
      icon: 'server',
      skills: ['Linux Administration', 'TCP/IP', 'Load Balancing', 'Nginx', 'IIS', 'Git'],
    },
  ];

  protected readonly experiences = [
    {
      period: 'Jun 2024 — Present',
      title: 'DevOps Engineer',
      company: 'Purple Group',
      bullets: [
        'Designed and provisioned AWS infrastructure using IaC for consistency and scalability.',
        'Automated deployment workflows with Ansible for parallel, repeatable releases.',
        'Migrated legacy on-prem workloads to AWS, improving reliability and deployment speed.',
        'Re-architected CI/CD pipelines from Octopus Deploy to Jenkins, supporting ECS, Kubernetes, and IIS.',
        'Built a centralized developer platform using Backstage for self-service and visibility.',
        'Implemented monitoring with Kibana and Prometheus for incident detection.',
        'Created custom AMIs using Packer for Jenkins build agents.',
      ],
    },
    {
      period: 'Aug 2022 — May 2024',
      title: 'Cloud Engineer',
      company: 'Stratpoint Global Outsourcing',
      bullets: [
        'Provisioned AWS services using IaC and manual methods.',
        'Collaborated with project teams to ensure seamless cloud transitions.',
        'Executed automation with Ansible for post-provisioning and Packer for golden images.',
        'Managed sysadmin tasks across cloud and on-premises environments.',
        'Proficient in troubleshooting Linux systems and networking issues.',
      ],
    },
  ];

  protected readonly education = [
    {
      period: '2018 — 2022',
      degree: 'Bachelor of Science in Computer Engineering',
      school: 'Polytechnic University of the Philippines',
    },
    {
      period: '2016 — 2018',
      degree: 'SHS: Science, Technology, Engineering and Mathematics (STEM)',
      school: 'Our Lady of Fatima University',
    },
  ];

  protected readonly certifications = [
    {
      name: 'HashiCorp Certified: Terraform Associate (003)',
      date: 'Sep 18, 2023',
      url: 'https://www.credly.com/badges/77c70043-f2ca-40f5-9e30-368f4e3c4cae/public_url',
    },
  ];

  protected readonly socialLinks = [
    {
      name: 'LinkedIn',
      icon: 'linkedin',
      url: 'https://www.linkedin.com/in/catibag-ronald/',
    },
    {
      name: 'Email',
      icon: 'email',
      url: 'mailto:catibagronald@gmail.com',
    },
    {
      name: 'Phone',
      icon: 'phone',
      url: 'tel:+6309760230770',
    },
  ];
}
