import { mkdir, readFile, readdir, rename, stat, writeFile } from "node:fs/promises"
import { homedir } from "node:os"
import { dirname, join, resolve } from "node:path"
import { Plugin } from "@opencode/plugin/tui"

const PLUGIN_ID = "folder-switcher"
const CONFIG_DIR = join(homedir(), ".config", "opencode")
const RECENTS_PATH = join(CONFIG_DIR, "folder-switcher.json")
const MAX_RECENTS = 10
const MAX_CHILDREN = 200

type Choice = { readonly kind: "move"; readonly directory: string } | { readonly kind: "manual" }

function describeError(error: unknown): string {
  const code = (error as { code?: string } | undefined)?.code
  const message = error instanceof Error ? error.message : String(error)
  return code ? `${code}: ${message}` : message
}

function expandHome(value: string): string {
  if (value === "~") return homedir()
  if (value.startsWith("~/")) return join(homedir(), value.slice(2))
  return value
}

async function readRecents(): Promise<string[]> {
  try {
    const parsed: unknown = JSON.parse(await readFile(RECENTS_PATH, "utf8"))
    const list = Array.isArray(parsed) ? parsed : (parsed as { recent?: unknown })?.recent
    if (!Array.isArray(list)) return []
    return list.filter((item): item is string => typeof item === "string" && item.length > 0)
  } catch {
    return []
  }
}

async function saveRecent(directory: string): Promise<void> {
  const previous = await readRecents()
  const next = [directory, ...previous.filter((item) => item !== directory)].slice(0, MAX_RECENTS)
  await mkdir(CONFIG_DIR, { recursive: true })
  const temp = `${RECENTS_PATH}.${process.pid}.tmp`
  await writeFile(temp, `${JSON.stringify({ recent: next }, null, 2)}\n`, "utf8")
  await rename(temp, RECENTS_PATH)
}

export default Plugin.define({
  id: PLUGIN_ID,
  async setup(context) {
    const alert = (message: string) => context.ui.dialog.alert({ title: "Смена каталога", message })

    const currentDirectory = (): string | undefined => {
      try {
        if (context.location?.directory) return context.location.directory
        return context.data.location.default()?.directory ?? process.cwd()
      } catch {
        return process.cwd()
      }
    }

    const promptDirectory = async (base: string): Promise<string | undefined> => {
      const entered = await context.ui.dialog.prompt({
        title: "Введите путь к каталогу",
        description: base,
        placeholder: "/абсолютный/путь или ../relative",
        value: base,
      })
      const trimmed = entered?.trim()
      if (!trimmed) return undefined
      return resolve(base, expandHome(trimmed))
    }

    const show = async (): Promise<void> => {
      const route = context.ui.router.current()
      const sessionID = route.type === "session" ? route.sessionID : undefined
      if (!sessionID) {
        await alert("Нет активной сессии: откройте сессию и повторите /cd.")
        return
      }

      const directory = currentDirectory()
      if (!directory) {
        await alert("Не удалось определить текущий каталог сессии.")
        return
      }

      const options: { title: string; value: Choice; description?: string; category?: string }[] = []

      const parent = dirname(directory)
      if (parent !== directory) {
        options.push({ title: "..", description: parent, category: "Навигация", value: { kind: "move", directory: parent } })
      }

      try {
        const entries = await readdir(directory, { withFileTypes: true })
        const children = entries
          .filter((entry) => entry.isDirectory())
          .map((entry) => entry.name)
          .sort((a, b) => a.localeCompare(b, "ru", { numeric: true }))
        for (const name of children.slice(0, MAX_CHILDREN)) {
          options.push({ title: `${name}/`, category: "Подкаталоги", value: { kind: "move", directory: join(directory, name) } })
        }
        if (children.length > MAX_CHILDREN) {
          options.push({
            title: `… ещё ${children.length - MAX_CHILDREN} каталогов`,
            description: "Введите имя вручную",
            category: "Подкаталоги",
            value: { kind: "manual" },
          })
        }
      } catch (error) {
        await alert(`Не удалось прочитать ${directory}\n${describeError(error)}`)
      }

      for (const recent of await readRecents()) {
        if (recent === directory) continue
        options.push({ title: recent, description: "недавний", category: "Недавние", value: { kind: "move", directory: recent } })
      }

      options.push({
        title: "Ввести путь вручную",
        description: "Абсолютный путь, ~/… или путь относительно текущего каталога",
        category: "Действие",
        value: { kind: "manual" },
      })

      const choice = await context.ui.dialog.select<Choice>({
        title: `Каталог сессии: ${directory}`,
        placeholder: "Фильтр по имени каталога",
        options,
      })
      if (!choice) return

      const target = choice.kind === "manual" ? await promptDirectory(directory) : choice.directory
      if (!target || target === directory) return

      try {
        const info = await stat(target)
        if (!info.isDirectory()) throw new Error("Это не каталог")
      } catch (error) {
        await alert(`Каталог недоступен: ${target}\n${describeError(error)}`)
        return
      }

      try {
        await context.client.session.move({ sessionID, directory: target })
      } catch (error) {
        await alert(`Не удалось переместить сессию в ${target}\n${describeError(error)}`)
        return
      }

      try {
        await saveRecent(target)
      } catch (error) {
        context.ui.toast.show({
          title: "folder-switcher",
          message: `Сессия перемещена, но список недавних не сохранён: ${describeError(error)}`,
          variant: "warning",
        })
      }

      context.ui.toast.show({ title: "folder-switcher", message: `Каталог: ${target}`, variant: "success" })
    }

    context.keymap.layer(() => ({
      commands: [
        {
          id: `${PLUGIN_ID}.open`,
          title: "Сменить каталог сессии",
          description: "Выбрать папку и переместить текущую сессию",
          group: "Навигация",
          bind: false,
          palette: true,
          slash: { name: "cd", aliases: ["folder"] },
          run: show,
        },
      ],
    }))
  },
})
