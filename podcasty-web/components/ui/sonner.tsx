"use client"

import { useTheme } from "next-themes"
import { Toaster as Sonner } from "sonner"

type ToasterProps = React.ComponentProps<typeof Sonner>

const Toaster = ({ ...props }: ToasterProps) => {
  const { theme = "system" } = useTheme()

  return (
    <Sonner
      theme={theme as ToasterProps["theme"]}
      className="toaster group"
      position="bottom-right"
      toastOptions={{
        classNames: {
          toast:
            "group toast !bg-[var(--app-surface)] !text-[var(--app-text)] !border-[var(--app-border)] !shadow-[var(--app-shadow-md)] rounded-xl",
          description: "!text-[var(--app-muted)]",
          actionButton:
            "!bg-[var(--app-accent)] !text-white",
          cancelButton:
            "!bg-[var(--app-raised)] !text-[var(--app-muted)]",
          error: "!border-red-500/30",
          success: "!border-[var(--app-accent)]/30",
        },
      }}
      {...props}
    />
  )
}

export { Toaster }
