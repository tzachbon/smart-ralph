/**
 * Type declarations for markdown files imported with Bun's text attribute
 * @see https://bun.sh/docs/bundler/loaders#text
 */
declare module "*.md" {
  const content: string;
  export default content;
}
