import { defineConfig } from 'vitepress'

const repo = 'https://github.com/zh1peng/ManualQC'
const chapters = [
  ['start', 'Load your first dataset', '加载第一份数据'],
  ['epochs', 'Review epochs', '审查 epoch'],
  ['channels-ics', 'Inspect channels and ICs', '查看通道与独立成分'],
  ['save', 'Save and verify', '保存并核对结果'],
  ['raters', 'Compare raters', '比较评分者'],
  ['agreement', 'Interpret agreement', '解读一致性指标']
]
function navigation(zh = false) {
  const root = zh ? '/zh/' : '/'
  return {
    nav: [{ text: zh ? '手册' : 'Handbook', link: root }, { text: zh ? '快速开始' : 'Quickstart', link: root + 'guide/start' }],
    sidebar: [
      { text: zh ? '使用手册' : 'Field manual', items: [{text: zh ? '概览' : 'Overview', link: root}] },
      { text: zh ? '单人质量控制' : 'Single-rater QC', items: chapters.slice(0,4).map(item) },
      { text: 'RaterTool', items: chapters.slice(4).map(item) }
    ]
  }
  function item(c: string[]) { return { text: c[zh ? 2 : 1], link: root + 'guide/' + c[0] } }
}

export default defineConfig({
  base: '/ManualQC/',
  title: 'ManualQC',
  description: 'An illustrated field manual for EEG quality control with MATLAB and EEGLAB.',
  head: [['link', { rel: 'icon', href: '/ManualQC/manualqc.svg', type: 'image/svg+xml' }]],
  locales: {
    root: { label: 'English', lang: 'en-US', themeConfig: navigation() },
    zh: { label: '简体中文', lang: 'zh-CN', themeConfig: {
      ...navigation(true), outlineTitle: '本页内容', docFooter: { prev: '上一章', next: '下一章' }, sidebarMenuLabel: '目录', returnToTopLabel: '返回顶部'
    } }
  },
  themeConfig: {
    logo: '/manualqc.svg',
    search: { provider: 'local' },
    socialLinks: [{ icon: 'github', link: repo }],
    outline: [2, 3]
  }
})
