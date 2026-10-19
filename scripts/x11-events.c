/*
 * Exo for XFCE — X11 event helper.
 *
 * Emits window-manager state on stdout, and only when something actually
 * changed, so the shell gets instant updates instead of polling wmctrl.
 *
 * Protocol (one line per update, terminated by '\n'):
 *
 *   DESKTOP <active>|<count>|<name>|<name>|...
 *   ACTIVE <window-id>
 *   WINDOWS <id>|<desktop>|<pid>|<wmclass>|<title>;<tab>...
 *           (records separated by tab; <pid> is _NET_WM_PID, 0 when unset)
 *   FULLSCREEN <0|1>
 *
 * Build:  cc -O2 -o bin/x11-events scripts/x11-events.c -lxcb
 * (or just run scripts/setup.sh)
 *
 * A fallback that produces the same protocol using wmctrl/xprop lives in
 * scripts/x11-poll.sh; the shell picks whichever one is available.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <poll.h>

#include <xcb/xcb.h>

#define ATOMS(X)                                 \
	X(_NET_CURRENT_DESKTOP)                      \
	X(_NET_NUMBER_OF_DESKTOPS)                   \
	X(_NET_DESKTOP_NAMES)                        \
	X(_NET_CLIENT_LIST)                          \
	X(_NET_ACTIVE_WINDOW)                        \
	X(_NET_WM_DESKTOP)                           \
	X(_NET_WM_STATE)                             \
	X(_NET_WM_STATE_FULLSCREEN)                  \
	X(_NET_WM_NAME)                              \
	X(UTF8_STRING)                               \
	X(_NET_WM_PID)                               \
	X(WM_NAME)                                   \
	X(WM_CLASS)                                  \
	X(STRING)

enum {
#define X(name) A_##name,
	ATOMS(X)
#undef X
	ATOM_COUNT
};

static xcb_connection_t *conn;
static xcb_window_t root;
static xcb_atom_t atoms[ATOM_COUNT];

static char last_desktops[4096];
static char last_active[64];
static char last_windows[65536];
static char last_fullscreen[8];

static xcb_atom_t intern_atom(const char *name) {
	xcb_intern_atom_cookie_t cookie = xcb_intern_atom(conn, 0, (uint16_t)strlen(name), name);
	xcb_intern_atom_reply_t *reply = xcb_intern_atom_reply(conn, cookie, NULL);
	if (!reply) {
		return XCB_ATOM_NONE;
	}
	xcb_atom_t atom = reply->atom;
	free(reply);
	return atom;
}

/* Returns a malloc'd copy of the property data, or NULL. */
static void *get_property(xcb_window_t window, xcb_atom_t property, xcb_atom_t type, unsigned long *count, xcb_atom_t *actual_type) {
	xcb_get_property_cookie_t cookie =
	    xcb_get_property(conn, 0, window, property, type, 0, 0x1FFFFFFF);
	xcb_get_property_reply_t *reply = xcb_get_property_reply(conn, cookie, NULL);
	if (!reply) {
		return NULL;
	}
	if (reply->type == XCB_ATOM_NONE || reply->value_len == 0) {
		free(reply);
		return NULL;
	}
	int length = xcb_get_property_value_length(reply);
	void *data = malloc((size_t)length + 1);
	if (!data) {
		free(reply);
		return NULL;
	}
	memcpy(data, xcb_get_property_value(reply), (size_t)length);
	((char *)data)[length] = '\0';
	if (count) {
		*count = reply->value_len;
	}
	if (actual_type) {
		*actual_type = reply->type;
	}
	free(reply);
	return data;
}

static unsigned int get_cardinal(xcb_window_t window, xcb_atom_t property, unsigned int fallback) {
	unsigned long count = 0;
	unsigned int *value = get_property(window, property, XCB_ATOM_CARDINAL, &count, NULL);
	if (!value || count < 1) {
		free(value);
		return fallback;
	}
	unsigned int result = value[0];
	free(value);
	return result;
}

static int emit(const char *cache, size_t cache_size, const char *line) {
	if (strcmp(cache, line) == 0) {
		return 0;
	}
	snprintf((char *)cache, cache_size, "%s", line);
	fputs(line, stdout);
	fputc('\n', stdout);
	fflush(stdout);
	return 1;
}

static void print_desktops(void) {
	unsigned int count = get_cardinal(root, atoms[A__NET_NUMBER_OF_DESKTOPS], 1);
	unsigned int current = get_cardinal(root, atoms[A__NET_CURRENT_DESKTOP], 0);

	char line[4096];
	int offset = snprintf(line, sizeof(line), "DESKTOP %u|%u|", current, count);

	unsigned long names_len = 0;
	char *names = get_property(root, atoms[A__NET_DESKTOP_NAMES], atoms[A_UTF8_STRING], &names_len, NULL);
	if (!names) {
		names = get_property(root, atoms[A__NET_DESKTOP_NAMES], XCB_ATOM_ANY, &names_len, NULL);
	}

	for (unsigned int i = 0; i < count; i++) {
		const char *name = NULL;
		if (names) {
			/* The list is NUL separated; walk to the i-th entry. */
			const char *cursor = names;
			for (unsigned int j = 0; j < i && cursor < names + names_len; j++) {
				cursor += strlen(cursor) + 1;
			}
			if (cursor < names + names_len && *cursor != '\0') {
				name = cursor;
			}
		}

		char fallback[32];
		if (!name) {
			snprintf(fallback, sizeof(fallback), "Workspace %u", i + 1);
			name = fallback;
		}

		/* Names must not contain the separators. */
		char cleaned[128];
		snprintf(cleaned, sizeof(cleaned), "%s", name);
		for (char *p = cleaned; *p; p++) {
			if (*p == '|' || *p == '\t' || *p == '\n') {
				*p = ' ';
			}
		}

		if (i > 0) {
			offset += snprintf(line + offset, sizeof(line) - (size_t)offset, "|");
		}
		offset += snprintf(line + offset, sizeof(line) - (size_t)offset, "%s", cleaned);
		if ((size_t)offset >= sizeof(line) - 2) {
			break;
		}
	}

	free(names);
	emit(last_desktops, sizeof(last_desktops), line);
}

static void select_client_events(void) {
	/* Watch property changes on every client so title changes are noticed. */
	unsigned long count = 0;
	xcb_window_t *clients = get_property(root, atoms[A__NET_CLIENT_LIST], XCB_ATOM_WINDOW, &count, NULL);
	if (!clients) {
		return;
	}
	for (unsigned long i = 0; i < count; i++) {
		uint32_t mask = XCB_EVENT_MASK_PROPERTY_CHANGE;
		xcb_change_window_attributes(conn, clients[i], XCB_CW_EVENT_MASK, &mask);
	}
	free(clients);
}

static void print_windows(void) {
	char line[65536];
	int offset = snprintf(line, sizeof(line), "WINDOWS ");

	unsigned long count = 0;
	xcb_window_t *clients = get_property(root, atoms[A__NET_CLIENT_LIST], XCB_ATOM_WINDOW, &count, NULL);

	for (unsigned long i = 0; clients && i < count; i++) {
		xcb_window_t window = clients[i];

		unsigned int desktop = get_cardinal(window, atoms[A__NET_WM_DESKTOP], 0xFFFFFFFFu);
		int desktop_value = desktop == 0xFFFFFFFFu ? -1 : (int)desktop;

		/* _NET_WM_PID lets the shell recognise (and hide) its own surfaces. */
		unsigned int pid = get_cardinal(window, atoms[A__NET_WM_PID], 0);

		/* WM_CLASS holds "instance\0class\0"; report class, matching wmctrl. */
		char wmclass[256] = "N/A";
		unsigned long class_len = 0;
		char *class_data = get_property(window, atoms[A_WM_CLASS], atoms[A_STRING], &class_len, NULL);
		if (!class_data) {
			class_data = get_property(window, atoms[A_WM_CLASS], XCB_ATOM_ANY, &class_len, NULL);
		}
		if (class_data) {
			size_t first = strlen(class_data);
			size_t total = class_len * 1; /* value_len is bytes for STRING */
			if (first + 1 < total) {
				snprintf(wmclass, sizeof(wmclass), "%s.%s", class_data, class_data + first + 1);
			} else if (first > 0) {
				snprintf(wmclass, sizeof(wmclass), "%s", class_data);
			}
			free(class_data);
		}

		char title[512] = "";
		unsigned long title_len = 0;
		char *title_data = get_property(window, atoms[A__NET_WM_NAME], atoms[A_UTF8_STRING], &title_len, NULL);
		if (!title_data) {
			title_data = get_property(window, atoms[A_WM_NAME], XCB_ATOM_ANY, &title_len, NULL);
		}
		if (title_data) {
			snprintf(title, sizeof(title), "%s", title_data);
			free(title_data);
		}

		/* Separators must not appear inside fields. */
		for (char *p = wmclass; *p; p++) {
			if (*p == '|' || *p == '\t' || *p == '\n') {
				*p = ' ';
			}
		}
		for (char *p = title; *p; p++) {
			if (*p == '|' || *p == '\t' || *p == '\n') {
				*p = ' ';
			}
		}

		offset += snprintf(line + offset, sizeof(line) - (size_t)offset, "0x%08x|%d|%u|%s|%s\t", (unsigned int)window, desktop_value, pid, wmclass, title);
		if ((size_t)offset >= sizeof(line) - 1024) {
			break;
		}
	}

	free(clients);
	emit(last_windows, sizeof(last_windows), line);
}

static void print_active(void) {
	unsigned long count = 0;
	xcb_window_t *active = get_property(root, atoms[A__NET_ACTIVE_WINDOW], XCB_ATOM_WINDOW, &count, NULL);

	char line[64];
	if (active && count > 0) {
		snprintf(line, sizeof(line), "ACTIVE 0x%08x", (unsigned int)active[0]);
	} else {
		snprintf(line, sizeof(line), "ACTIVE 0x0");
	}
	free(active);
	emit(last_active, sizeof(last_active), line);
}

static void print_fullscreen(void) {
	unsigned long count = 0;
	xcb_window_t *active = get_property(root, atoms[A__NET_ACTIVE_WINDOW], XCB_ATOM_WINDOW, &count, NULL);

	int fullscreen = 0;
	if (active && count > 0) {
		unsigned long state_count = 0;
		xcb_atom_t *states = get_property(active[0], atoms[A__NET_WM_STATE], XCB_ATOM_ATOM, &state_count, NULL);
		for (unsigned long i = 0; states && i < state_count; i++) {
			if (states[i] == atoms[A__NET_WM_STATE_FULLSCREEN]) {
				fullscreen = 1;
			}
		}
		free(states);
	}
	free(active);

	char line[16];
	snprintf(line, sizeof(line), "FULLSCREEN %d", fullscreen);
	emit(last_fullscreen, sizeof(last_fullscreen), line);
}

static void print_all(int reselect) {
	if (reselect) {
		select_client_events();
	}
	print_desktops();
	print_active();
	print_windows();
	print_fullscreen();
}

int main(void) {
	int screen_index = 0;
	conn = xcb_connect(NULL, &screen_index);
	if (xcb_connection_has_error(conn)) {
		fprintf(stderr, "x11-events: cannot connect to the X server (is DISPLAY set?)\n");
		return 1;
	}

	const xcb_setup_t *setup = xcb_get_setup(conn);
	xcb_screen_iterator_t iterator = xcb_setup_roots_iterator(setup);
	for (int i = 0; i < screen_index; i++) {
		xcb_screen_next(&iterator);
	}
	xcb_screen_t *screen = iterator.data;
	if (!screen) {
		fprintf(stderr, "x11-events: no screen found\n");
		return 1;
	}
	root = screen->root;

	static const char *atom_names[] = {
#define X(name) #name,
	    ATOMS(X)
#undef X
	};
	for (int i = 0; i < ATOM_COUNT; i++) {
		atoms[i] = intern_atom(atom_names[i]);
	}

	uint32_t mask = XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY | XCB_EVENT_MASK_PROPERTY_CHANGE;
	xcb_change_window_attributes(conn, root, XCB_CW_EVENT_MASK, &mask);
	xcb_flush(conn);

	/* Initial state. */
	print_all(1);

	/* Reset the caches so the first real update is always sent. */
	last_desktops[0] = '\0';
	last_active[0] = '\0';
	last_windows[0] = '\0';
	last_fullscreen[0] = '\0';

	int fd = xcb_get_file_descriptor(conn);
	for (;;) {
		int dirty = 0;

		/* Block until something happens, then coalesce bursts. */
		struct pollfd pfd = { .fd = fd, .events = POLLIN };
		if (poll(&pfd, 1, -1) <= 0) {
			continue;
		}

		xcb_generic_event_t *event;
		while ((event = xcb_poll_for_event(conn)) != NULL) {
			uint8_t type = event->response_type & 0x7f;
			switch (type) {
			case XCB_PROPERTY_NOTIFY:
			case XCB_MAP_NOTIFY:
			case XCB_UNMAP_NOTIFY:
			case XCB_DESTROY_NOTIFY:
			case XCB_CLIENT_MESSAGE:
			case XCB_CONFIGURE_NOTIFY:
				dirty = 1;
				break;
			default:
				break;
			}
			free(event);
		}

		if (dirty) {
			/* Let a burst of events settle before emitting. */
			usleep(30000);
			while ((event = xcb_poll_for_event(conn)) != NULL) {
				free(event);
			}
			print_all(1);
		}
	}

	xcb_disconnect(conn);
	return 0;
}
