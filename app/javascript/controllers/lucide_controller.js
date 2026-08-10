import { Controller } from "@hotwired/stimulus"
import { createIcons, Calendar, CloudSun, Target, Activity,
         ClipboardList, Star, Zap, Mail, List, AlertCircle,
         Send, Bell, ChevronDown, Sun, Circle, CheckCircle,
         Bot, ListChecks, User, Briefcase, Moon, Sunset, CloudRain } from "lucide"

// Connects to data-controller="lucide"
export default class extends Controller {
  connect() {
    createIcons({
      icons: {
        Calendar,
        CloudSun,
        Target,
        Activity,
        ClipboardList,
        Star,
        Zap,
        Mail,
        List,
        AlertCircle,
        Send,
        Bell,
        ChevronDown,
        Sun,
        Circle,
        CheckCircle,
        Bot,
        ListChecks,
        User,
        Briefcase,
        Moon,
        Sunset,
        CloudRain
      }
    })
  }
}
