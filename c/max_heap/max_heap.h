#include <stdbool.h>
#include <stddef.h>

#define ARR_SIZE 12

/**
 * @brief initialize an array of a specific size
 *
 * @return the array
 */
int *init_array();

/**
 * @brief check if an element is in boudns in regard to ARR_SIZE
 *
 * @param[in] pos the index of the item to check
 * @return whether or not the index is in bounds
 */
bool in_bounds(int pos);

/**
 * @brief Returns position for parent
 *
 * @param[in] pos the index of the item to check
 * @return the parent index of pos
 */
int parent_index(int pos);

/**
 * @brief Returns left child index
 *
 * @param[in] pos the index of the item to check
 * @return the left child index
 */
int left_child_index(int pos);

/**
 * @brief Returns right child index
 *
 * @param[in] pos the index of the item to check
 * @return The right child index
 */
int right_child_index(int pos);

/**
 * @brief Returns the left sibling index
 *
 * @param[in] pos the index of the item to check
 * @return The left sibling index
 */
int left_sibling_index(int pos);

/**
 * @brief Returns the right sibling index
 *
 * @param[in] pos the index of the item to check
 * @return The right sibling index
 */
int right_sibling_index(int pos);

/**
 * @brief Check whether or not an index is a leaf node
 *
 * @param[in] pos the index of the item to check
 * @param[in] items_in_arr the number of items in the array
 * @return Whether or not the index is a leaf
 */
bool is_leaf(int pos, size_t items_in_arr);

/**
 * @brief Swaps two elements in an array
 *
 * @param[in] arr The array
 * @param[in] i The first index to swap
 * @param[in] j The second index to swap
 */
void swap(int *arr, int i, int j);

/**
 * @brief Moves an element up to its correct place
 *
 * @param[in] arr The array
 * @param[in] pos the index of the item to check
 */
void sift_up(int *arr, int pos);

/**
 * @brief Moves an element down to its correct place
 *
 * @param[in] arr The array
 * @param[in] pos the index of the item to check
 * @param[in] items_in_arr number of items in the array
 */
void sift_down(int *arr, int pos, int items_in_arr);

/**
 * @brief Insert value into heap
 *
 * @param[in] arr The array
 * @param[in] items_in_arr Number of items in the array
 * @param[in] val Value to insert
 */
void insert_into_heap(int *arr, int *items_in_arr, int val);

/**
 * @brief Pretty print the tree
 *
 * @param[in] arr The array
 * @param[in] items_in_arr Number of items in the array
 */
void pretty_print_tree(int *arr, int items_in_arr);

/**
 * @brief Build an array into a heap
 *
 * @param[in] arr The array
 * @param[in] items_in_arr Number of items in the array
 */
void build_heap(int *arr, int items_in_arr);

/**
 * @brief Remove the max value from the heap
 *
 * @param[in] arr The array
 * @param[in] items_in_arr Number of items in the array
 * @return The max value
 */
int remove_max(int *arr, int *items_in_arr);

/**
 * @brief Remove a specified index from the heap
 *
 * @param[in] arr The array
 * @param[in] pos the index of the item to check
 * @param[in] items_in_arr Number of items in the array
 * @return The item at the specified index
 */
int remove_index(int *arr, int pos, int *items_in_arr);

/**
 * @brief The value at pos has been changed, retore the heap property
 *
 * @param[in] arr The array
 * @param[in] pos the index of the item to check
 * @param[in] items_in_arr Number of items in the array
 */
void update(int *arr, int pos, int items_in_arr);

/**
 * @brief Modify the value at the given position
 *
 * @param[in] arr The array
 * @param[in] pos the index of the item to modify
 * @param[in] new_val The value to replace with
 * @param[in] items_in_arr Number of items in the array
 */
void modify(int *arr, int pos, int new_val, int items_in_arr);
