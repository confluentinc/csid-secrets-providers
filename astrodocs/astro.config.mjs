import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

import robotsTxt from 'astro-robots-txt'
// https://astro.build/config
export default defineConfig({
    build: {
        inlineStylesheets: 'always'
    },
	integrations: [
		starlight({
			title: 'Secret Providers',
			editLink: {
			    baseUrl: 'https://github.com/confluentinc/csid-secrets-provider/edit/main/astrodocs/'
			},
			logo: {
			    light: '/src/assets/confluent.svg',
			    dark: '/src/assets/confluent-dark.svg'
			},
			sidebar: [{
            			label: 'Home',
            			items: [{
            				label: 'Introduction',
            				link: '/'
            			}]
            		}, {
            			label: 'Explanation',
            			autogenerate: {
            				directory: 'explanation'
            			}
            		}, {
            			label: 'Guides',
            			autogenerate: {
            				directory: 'guides'
            			}
            		}, {
            			label: 'Reference',
            			autogenerate: {
            				directory: 'reference'
            			}
            		}]
            	}),
            		robotsTxt({
            			policy: [{
            				userAgent: '*',
            				disallow: ['/']
            			}]
            		})
            	],
            	site: 'https://confluentinc.github.io/csid-secrets-provider/',
            	base: '/csid-secrets-provider'
            })
