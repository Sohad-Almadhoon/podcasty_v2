"use client";

import { useState } from "react";

interface DataPoint {
  date: string;
  count: number;
}

const CHART_WIDTH = 700;
const CHART_HEIGHT = 200;
const PADDING = { top: 20, right: 20, bottom: 30, left: 45 };

const AnalyticsCharts = ({ data }: { data: DataPoint[] }) => {
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null);

  if (data.length === 0) return null;

  const visible = data.slice(-30);
  const maxCount = Math.max(...visible.map((d) => d.count), 1);

  // Round up max to nearest nice number for Y-axis
  const niceMax = getNiceMax(maxCount);
  const yTicks = getYTicks(niceMax);

  const plotW = CHART_WIDTH - PADDING.left - PADDING.right;
  const plotH = CHART_HEIGHT - PADDING.top - PADDING.bottom;

  // Map data points to SVG coordinates
  const points = visible.map((d, i) => ({
    x: PADDING.left + (visible.length === 1 ? plotW / 2 : (i / (visible.length - 1)) * plotW),
    y: PADDING.top + plotH - (d.count / niceMax) * plotH,
    ...d,
  }));

  // Build the line path
  const linePath = points.map((p, i) => `${i === 0 ? "M" : "L"} ${p.x} ${p.y}`).join(" ");

  // Build the area path (line + close along bottom)
  const areaPath = `${linePath} L ${points[points.length - 1].x} ${PADDING.top + plotH} L ${points[0].x} ${PADDING.top + plotH} Z`;

  // X-axis labels: show ~5 evenly spaced
  const xLabelCount = Math.min(visible.length, 5);
  const xLabels: { x: number; label: string }[] = [];
  for (let i = 0; i < xLabelCount; i++) {
    const idx = xLabelCount === 1
      ? 0
      : Math.round((i / (xLabelCount - 1)) * (visible.length - 1));
    xLabels.push({ x: points[idx].x, label: formatDate(visible[idx].date) });
  }

  const hovered = hoveredIndex !== null ? points[hoveredIndex] : null;

  const totalPlays = visible.reduce((s, d) => s + d.count, 0);
  const avgPlays = visible.length > 0 ? Math.round(totalPlays / visible.length) : 0;
  const peakDay = visible.reduce((best, d) => (d.count > best.count ? d : best), visible[0]);

  return (
    <div className="rounded-xl border border-app-border bg-app-surface p-5">
      {/* Stats row */}
      <div className="flex items-center gap-6 mb-4">
        <div>
          <p className="text-[10px] uppercase tracking-wider text-app-subtle">Total</p>
          <p className="text-lg font-bold text-app-text tabular-nums">{totalPlays.toLocaleString()}</p>
        </div>
        <div className="h-8 w-px bg-app-border" />
        <div>
          <p className="text-[10px] uppercase tracking-wider text-app-subtle">Daily Avg</p>
          <p className="text-lg font-bold text-app-text tabular-nums">{avgPlays.toLocaleString()}</p>
        </div>
        <div className="h-8 w-px bg-app-border" />
        <div>
          <p className="text-[10px] uppercase tracking-wider text-app-subtle">Peak</p>
          <p className="text-lg font-bold text-app-text tabular-nums">
            {peakDay.count.toLocaleString()}
            <span className="text-[10px] font-normal text-app-subtle ml-1">{formatDate(peakDay.date)}</span>
          </p>
        </div>
      </div>

      {/* Chart */}
      <div className="relative w-full" style={{ aspectRatio: `${CHART_WIDTH}/${CHART_HEIGHT}` }}>
        <svg
          viewBox={`0 0 ${CHART_WIDTH} ${CHART_HEIGHT}`}
          className="w-full h-full"
          onMouseLeave={() => setHoveredIndex(null)}
        >
          <defs>
            <linearGradient id="areaGradient" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="rgb(147, 51, 234)" stopOpacity="0.3" />
              <stop offset="100%" stopColor="rgb(147, 51, 234)" stopOpacity="0.02" />
            </linearGradient>
          </defs>

          {/* Horizontal grid lines */}
          {yTicks.map((tick) => {
            const y = PADDING.top + plotH - (tick / niceMax) * plotH;
            return (
              <g key={tick}>
                <line
                  x1={PADDING.left}
                  y1={y}
                  x2={PADDING.left + plotW}
                  y2={y}
                  stroke="currentColor"
                  className="text-app-border"
                  strokeDasharray="4 4"
                  strokeWidth={0.5}
                />
                <text
                  x={PADDING.left - 8}
                  y={y + 3}
                  textAnchor="end"
                  className="fill-app-subtle"
                  fontSize={10}
                >
                  {tick >= 1000 ? `${(tick / 1000).toFixed(tick >= 10000 ? 0 : 1)}k` : tick}
                </text>
              </g>
            );
          })}

          {/* Area fill */}
          <path d={areaPath} fill="url(#areaGradient)" />

          {/* Line */}
          <path
            d={linePath}
            fill="none"
            stroke="rgb(147, 51, 234)"
            strokeWidth={2}
            strokeLinecap="round"
            strokeLinejoin="round"
          />

          {/* Data point dots */}
          {points.map((p, i) => (
            <circle
              key={i}
              cx={p.x}
              cy={p.y}
              r={hoveredIndex === i ? 5 : 3}
              fill={hoveredIndex === i ? "rgb(147, 51, 234)" : "transparent"}
              stroke={hoveredIndex === i ? "rgb(147, 51, 234)" : "transparent"}
              strokeWidth={2}
              className="transition-all duration-150"
            />
          ))}

          {/* Invisible hover targets (wider hit area) */}
          {points.map((p, i) => (
            <rect
              key={`hover-${i}`}
              x={p.x - plotW / visible.length / 2}
              y={PADDING.top}
              width={plotW / visible.length}
              height={plotH}
              fill="transparent"
              onMouseEnter={() => setHoveredIndex(i)}
              className="cursor-crosshair"
            />
          ))}

          {/* Hover vertical line */}
          {hovered && (
            <line
              x1={hovered.x}
              y1={PADDING.top}
              x2={hovered.x}
              y2={PADDING.top + plotH}
              stroke="rgb(147, 51, 234)"
              strokeWidth={1}
              strokeDasharray="4 4"
              opacity={0.5}
            />
          )}

          {/* X-axis labels */}
          {xLabels.map((label, i) => (
            <text
              key={i}
              x={label.x}
              y={CHART_HEIGHT - 5}
              textAnchor="middle"
              className="fill-app-subtle"
              fontSize={10}
            >
              {label.label}
            </text>
          ))}
        </svg>

        {/* Floating tooltip */}
        {hovered && (
          <div
            className="absolute pointer-events-none z-10"
            style={{
              left: `${(hovered.x / CHART_WIDTH) * 100}%`,
              top: `${(hovered.y / CHART_HEIGHT) * 100}%`,
              transform: "translate(-50%, -140%)",
            }}
          >
            <div className="bg-app-text text-app-bg rounded-lg px-3 py-1.5 shadow-lg text-center">
              <p className="text-sm font-bold tabular-nums">{hovered.count.toLocaleString()}</p>
              <p className="text-[10px] opacity-75">{formatDate(hovered.date)}</p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

function formatDate(dateStr?: string): string {
  if (!dateStr) return "";
  try {
    return new Intl.DateTimeFormat("en-US", { month: "short", day: "numeric" }).format(new Date(dateStr));
  } catch {
    return dateStr;
  }
}

function getNiceMax(max: number): number {
  if (max <= 5) return 5;
  if (max <= 10) return 10;
  const magnitude = Math.pow(10, Math.floor(Math.log10(max)));
  const normalized = max / magnitude;
  if (normalized <= 1.5) return Math.ceil(1.5 * magnitude);
  if (normalized <= 2.5) return Math.ceil(2.5 * magnitude);
  if (normalized <= 5) return Math.ceil(5 * magnitude);
  return Math.ceil(10 * magnitude);
}

function getYTicks(niceMax: number): number[] {
  const step = niceMax / 4;
  return [0, Math.round(step), Math.round(step * 2), Math.round(step * 3), niceMax];
}

export default AnalyticsCharts;
