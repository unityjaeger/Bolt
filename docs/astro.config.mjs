// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	site: "https://unityjaeger.github.io",
	base: "/Bolt/",
	integrations: [
		starlight({
			title: 'Bolt',
			tableOfContents: {minHeadingLevel: 2, maxHeadingLevel: 4},
			social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/unityjaeger/Bolt' }],
			sidebar: [
				{
					label: 'Guides',
					items: [
						// Each item here is one entry in the navigation menu.
						{ label: 'Introduction', slug: 'guides/intro' },
						{ label: "Shapes", slug: "guides/shapes" },
						{ label: "Special-Cased", slug: "guides/special_cased" },
						{ label: "GJK", slug: "guides/gjk" },
						{ label: "SAT", slug: "guides/sat" },
						{ label: "MPR", slug: "guides/mpr" },
						{ label: "AABB Tree", slug: "guides/aabb_tree" },
						{ label: "Meshes", slug: "guides/meshes" }
					],
				},
			],
		}),
	],
});