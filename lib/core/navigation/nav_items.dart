import 'package:flutter/material.dart';

import 'nav_item.dart';

const kNavGroups = <NavGroup>[
  NavGroup(
    title: null,
    items: [
      NavItem(
        label: 'Juegos',
        icon: Icons.sports_esports,
        route: '/juegos',
      ),
    ],
  ),
  NavGroup(
    title: 'Reportes',
    items: [
      NavItem(
        label: 'Facturas',
        icon: Icons.receipt_long,
        route: '/reportes/facturas',
      ),
      NavItem(
        label: 'Totales Sorteos',
        icon: Icons.dashboard_outlined,
        route: '/reportes/totales-sorteos',
      ),
      NavItem(
        label: 'Boletos Ganadores',
        icon: Icons.emoji_events_outlined,
        route: '/reportes/boletos-ganadores',
      ),
      NavItem(
        label: 'Últimos Resultados',
        icon: Icons.list_alt,
        route: '/reportes/ultimos-resultados',
      ),
      NavItem(
        label: 'Movimientos',
        icon: Icons.currency_exchange,
        route: '/reportes/movimientos',
      ),
    ],
  ),
  NavGroup(
    title: 'Herramientas',
    items: [
      NavItem(
        label: 'Guía de Sueños',
        icon: Icons.menu_book_outlined,
        route: '/herramientas/guia-suenos',
      ),
      NavItem(
        label: 'Cruz de la Suerte',
        icon: Icons.local_florist_outlined,
        route: '/herramientas/cruz-suerte',
      ),
      NavItem(
        label: 'Pirámide de la Suerte',
        icon: Icons.change_history,
        route: '/herramientas/piramide-suerte',
      ),
    ],
  ),
];
