/**
 * User Color Assignment Utility
 * Assigns consistent colors to users for presence indicators
 */

// Predefined color palette for user cursors
const USER_COLORS = [
  '#3B82F6', // Blue
  '#EF4444', // Red
  '#10B981', // Green
  '#8B5CF6', // Purple
  '#F59E0B', // Orange
  '#EC4899', // Pink
  '#14B8A6', // Teal
  '#F97316', // Amber
  '#6366F1', // Indigo
  '#84CC16', // Lime
  '#06B6D4', // Cyan
  '#D946EF', // Fuchsia
];

/**
 * Get consistent color for a user based on their ID
 * @param {string} userId - User ID
 * @returns {string} Hex color code
 */
function getUserColor(userId) {
  // Simple hash function to get consistent color
  let hash = 0;
  for (let i = 0; i < userId.length; i++) {
    hash = userId.charCodeAt(i) + ((hash << 5) - hash);
  }
  
  const index = Math.abs(hash) % USER_COLORS.length;
  return USER_COLORS[index];
}

/**
 * Get all available colors
 * @returns {Array<string>} Array of color hex codes
 */
function getAllColors() {
  return [...USER_COLORS];
}

/**
 * Get color name for display
 * @param {string} color - Hex color code
 * @returns {string} Color name
 */
function getColorName(color) {
  const colorNames = {
    '#3B82F6': 'Blue',
    '#EF4444': 'Red',
    '#10B981': 'Green',
    '#8B5CF6': 'Purple',
    '#F59E0B': 'Orange',
    '#EC4899': 'Pink',
    '#14B8A6': 'Teal',
    '#F97316': 'Amber',
    '#6366F1': 'Indigo',
    '#84CC16': 'Lime',
    '#06B6D4': 'Cyan',
    '#D946EF': 'Fuchsia',
  };
  
  return colorNames[color] || 'Unknown';
}

module.exports = {
  getUserColor,
  getAllColors,
  getColorName,
};
