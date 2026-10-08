/**
 * SF Symbol → lucide mapping, so content that stores symbol names
 * (situations, document kinds, update categories) renders consistently.
 */

import {
  ArrowLeftRight,
  Bell,
  BookOpen,
  BookMarked,
  Briefcase,
  Building2,
  Car,
  ClipboardList,
  Copy,
  FileText,
  GraduationCap,
  Home,
  IndianRupee,
  Landmark,
  Laptop,
  ListChecks,
  Percent,
  Quote,
  Scale,
  Sparkles,
  SquarePen,
  Users,
  WifiOff,
  type LucideIcon,
} from "lucide-react";

const symbolMap: Record<string, LucideIcon> = {
  "car.side": Car,
  "indianrupeesign.circle": IndianRupee,
  "wifi.exclamationmark": WifiOff,
  house: Home,
  "figure.2.arms.open": Users,
  briefcase: Briefcase,
  "building.columns": Landmark,
  "building.2": Building2,
  "text.quote": Quote,
  sparkles: Sparkles,
  "square.and.pencil": SquarePen,
  bell: Bell,
  "doc.text": FileText,
  graduationcap: GraduationCap,
  "doc.on.doc": Copy,
  checklist: ListChecks,
  "arrow.left.arrow.right": ArrowLeftRight,
  "book.closed": BookMarked,
  book: BookOpen,
  "scale.3d": Scale,
  "list.clipboard": ClipboardList,
};

export function symbolIcon(symbol: string): LucideIcon {
  return symbolMap[symbol] ?? BookOpen;
}

export const documentKindIcon: Record<string, LucideIcon> = {
  "bare-act": Landmark,
  "court-form": FileText,
  "exam-note": GraduationCap,
  "previous-paper": Copy,
  revision: ListChecks,
};

export const updateCategoryIcon: Record<string, LucideIcon> = {
  "supreme-court": Landmark,
  "high-court": Building2,
  judgment: Quote,
  "new-law": Sparkles,
  amendment: SquarePen,
  notification: Bell,
};

export const categoryIcon: Record<string, LucideIcon> = {
  criminal: Scale,
  constitutional: Landmark,
  civil: FileText,
  property: Home,
  family: Users,
  labour: Briefcase,
  taxation: Percent,
  "ip-tech": Laptop,
};
