// Previous / numbered / next buttons for any paginated list
export default function Pagination({
  page,
  totalPages,
  onChange,
}: {
  page: number;
  totalPages: number;
  onChange: (page: number) => void;
}) {
  if (totalPages <= 1) return null;
  return (
    <nav className="pagination" aria-label="Pages">
      <button type="button" disabled={page <= 1} onClick={() => onChange(page - 1)} aria-label="Previous page">
        ←
      </button>
      {Array.from({ length: totalPages }, (_, index) => (
        <button
          type="button"
          key={index}
          className={page === index + 1 ? "active" : ""}
          aria-current={page === index + 1 ? "page" : undefined}
          onClick={() => onChange(index + 1)}
        >
          {index + 1}
        </button>
      ))}
      <button
        type="button"
        disabled={page >= totalPages}
        onClick={() => onChange(page + 1)}
        aria-label="Next page"
      >
        →
      </button>
    </nav>
  );
}
