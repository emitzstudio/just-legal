import type { Config } from "tailwindcss";
import tailwindcssAnimate from "tailwindcss-animate";

export default {
  darkMode: ["class"],
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  prefix: "",
  theme: {
    container: {
      center: true,
      padding: "1.375rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      colors: {
        // LexIndia tokens (mirror LexColor on iOS)
        canvas: "var(--canvas)",
        surface: "var(--surface)",
        hairline: "var(--hairline)",
        faint: "var(--faint)",
        ink: "var(--ink)",
        slate: "var(--slate)",
        paper: "var(--paper)",
        "on-paper": "var(--on-paper)",
        brand: "var(--brand)",
        "brand-deep": "var(--brand-deep)",
        "brand-soft": "var(--brand-soft)",
        "on-brand": "var(--on-brand)",
        saffron: "var(--saffron)",
        "saffron-deep": "var(--saffron-deep)",
        "saffron-soft": "var(--saffron-soft)",
        "blue-soft": "var(--blue-soft)",
        "blue-deep": "var(--blue-deep)",
        mint: "var(--mint)",
        "mint-deep": "var(--mint-deep)",
        "frost-a": "var(--frost-a)",
        "frost-b": "var(--frost-b)",
        "frost-c": "var(--frost-c)",

        // shadcn bridge
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
        "2.5xl": "1.25rem",
        "3.5xl": "1.625rem",
      },
      fontSize: {
        "2xs": ["0.625rem", { lineHeight: "0.875rem" }],
      },
      boxShadow: {
        brand: "0 8px 18px -2px rgb(124 58 237 / 0.35)",
        float: "0 -6px 24px rgb(0 0 0 / 0.25)",
      },
      keyframes: {
        "accordion-down": {
          from: { height: "0" },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: "0" },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
      },
    },
  },
  plugins: [tailwindcssAnimate],
} satisfies Config;
