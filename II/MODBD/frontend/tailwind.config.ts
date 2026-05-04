import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        primary: "#207fdf",
        "primary-hover": "#1a6bc4",
        "background-light": "#f1f3f5",
        "background-dark": "#111921",
      },
      fontFamily: {
        display: ["var(--font-inter)", "Inter", "sans-serif"],
      },
      borderRadius: {
        card: "var(--radius-lg)",
        "card-xl": "var(--radius-xl)",
      },
      boxShadow: {
        card: "0 1px 3px 0 rgb(0 0 0 / 0.06), 0 1px 2px -1px rgb(0 0 0 / 0.06)",
        "card-hover": "0 4px 6px -1px rgb(0 0 0 / 0.08), 0 2px 4px -2px rgb(0 0 0 / 0.06)",
        "card-lg": "0 4px 6px -1px rgb(0 0 0 / 0.07), 0 2px 4px -2px rgb(0 0 0 / 0.05)",
        inner: "inset 0 1px 0 0 rgb(255 255 255 / 0.05)",
      },
      transitionDuration: {
        200: "200ms",
      },
    },
  },
  plugins: [],
};
export default config;
