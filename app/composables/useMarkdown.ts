import MarkdownIt from 'markdown-it'

export const useMarkdown = () => {
  const md = new MarkdownIt({
    html: false,
    linkify: true,
    typographer: true,
    breaks: true
  })

  const render = (content: string): string => {
    if (!content) return ''
    return md.render(content)
  }

  return {
    render
  }
}
